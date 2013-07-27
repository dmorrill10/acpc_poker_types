require 'acpc_poker_types/board_cards'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/rank'
require 'acpc_poker_types/suit'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/hand_player'

# Model to parse and manage information from a given match state string.
module AcpcPokerTypes

module PlayerGroupGenerator
  def player_group(
    stacks,
    antes,
    first_player_positions,
    min_wagers,
    betting_sequence
  )
    player_list = stacks.length.times.map do |i|
      HandPlayer.new all_hands[i], stacks[i], antes[i]
    end

    every_action(
      betting_sequence,
      player_list,
      first_player_positions
    ) do |action, round, acting_player_position|

      cost = action_cost(
        player_list,
        acting_player_position,
        action,
        min_wagers[round]
      )

      player_list[acting_player_position].append_action!(
        if cost > 0
          PokerAction.new(action.to_s, cost: cost)
        else
          action
        end,
        round
      )
    end

    player_list
  end

  def every_action(betting_sequence, player_list, first_player_positions)
    betting_sequence.each_with_index do |actions_per_round, round|
      acting_player_position = first_player_positions[round]

      actions_per_round.each do |action|
        acting_player_position = position_of_first_active_player(
          player_list,
          acting_player_position
        )

        yield action, round, acting_player_position

        acting_player_position = next_player_position(
          player_list.length,
          acting_player_position
        )
      end
    end
  end

  def next_player_position(num_players, acting_player_position=-1)
    (acting_player_position + 1) % num_players
  end

  def position_of_first_active_player(player_list, acting_player_position=0)
    raise NoPlayerCouldHaveActed if player_list.all? { |player| player.inactive? }

    # This must eventually exit because of the above assertion
    while player_list[acting_player_position].inactive?
      acting_player_position = next_player_position(
        player_list.length,
        acting_player_position
      )
    end
    acting_player_position
  end

  def action_cost(player_list, acting_player_position, action, min_wager)
    case action.to_s[0]
    when PokerAction::CALL
      amount_to_call player_list, acting_player_position
    when PokerAction::RAISE
      if action.modifier
        action.modifier.to_i - player_list[acting_player_position].total_contribution
      else
        min_wager + amount_to_call(player_list, acting_player_position)
      end
    else
      0
    end
  end

  def amount_to_call(player_list, acting_player_position)
    ChipStack.new(
      [
        (
          player_list.map do |player|
            player.total_contribution
          end
        ).max - player_list[acting_player_position].total_contribution,
        player_list[acting_player_position].stack
      ].min
    )
  end
end

class MatchState
  include PlayerGroupGenerator

  # @return [Integer] The position relative to the dealer of the player that
  #     received the match state string, indexed from 0, modulo the
  #     number of players.
  # @example The player immediately to the left of the dealer has
  #     +position_relative_to_dealer+ == 0
  # @example The dealer has
  #     +position_relative_to_dealer+ == <number of players> - 1
  attr_reader :position_relative_to_dealer

  # @return [Integer] The hand number.
  attr_reader :hand_number

  # @return [String] The ACPC string created by the given betting sequence.
  attr_reader :betting_sequence_string

  # @todo Move this @return [Array<Hand>] The list of visible hole card sets for each player.

  attr_reader :hands_string

  # @todo Move this @return [BoardCards] All visible community cards on the board.

  attr_reader :community_cards_string

  # @return [String] Label for match state strings.
  LABEL = 'MATCHSTATE'

  COMMUNITY_CARD_SEPARATOR = '/'
  BETTING_SEQUENCE_SEPARATOR = COMMUNITY_CARD_SEPARATOR
  HAND_SEPARATOR = '|'

  class << self; alias_method(:parse, :new) end

  # Receives a match state string from the given +connection+.
  # @param [#gets] connection The connection from which a match state string should be received.
  # @return [MatchState] The match state string that was received from the +connection+ or +nil+ if none could be received.
  def self.receive(connection)
    MatchState.parse connection.gets
  end

  # Builds a match state string from its given component parts.
  #
  # @param [#to_s] position_relative_to_dealer The position relative to the dealer.
  # @param [#to_s] hand_number The hand number.
  # @param [#to_s] betting_sequence The betting sequence.
  # @param [#to_s] all_hole_cards All the hole cards visible.
  # @param [#to_s, #empty?] board_cards All the community cards on the board.
  # @return [String] The constructed match state string.
  def self.build_match_state_string(
    position_relative_to_dealer,
    hand_number,
    betting_sequence,
    all_hole_cards,
    board_cards
  )
    string = "#{LABEL}:#{position_relative_to_dealer}:#{hand_number}:#{betting_sequence}:#{all_hole_cards}"
    string << "/#{board_cards.to_s}" if board_cards && !board_cards.empty?
    string
  end

  # @param [String] raw_match_state A raw match state string to be parsed.
  # @raise IncompleteMatchState
  def initialize(raw_match_state)
    if raw_match_state.match(
/#{LABEL}:(\d+):(\d+):([^:]*):([^#{COMMUNITY_CARD_SEPARATOR}]+)#{COMMUNITY_CARD_SEPARATOR}*([^\s:]*)/
    )
      @position_relative_to_dealer = $1.to_i
      @hand_number = $2.to_i
      @betting_sequence_string = $3
      @hands_string = $4
      @community_cards_string = $5
    end
  end

  # @return [String] The MatchState in raw text form.
  def to_str
    @str ||= MatchState.build_match_state_string(
      @position_relative_to_dealer,
      @hand_number,
      @betting_sequence_string,
      @hands_string,
      @community_cards_string
    )
  end

  # @see to_str
  alias_method :to_s, :to_str

  # @param [MatchState] another_match_state A match state string to compare against this one.
  # @return [Boolean] +true+ if this match state string is equivalent to +another_match_state+, +false+ otherwise.
  def ==(another_match_state)
    another_match_state.to_s == to_s
  end

  def all_hands
    @all_hands ||= -> do
      lcl_hole_card_hands = all_string_hands(@hands_string).map do |string_hand|
        Hand.from_acpc string_hand
      end
      while lcl_hole_card_hands.length < number_of_players
        lcl_hole_card_hands.push Hand.new
      end
      lcl_hole_card_hands
    end.call
  end

  # @return [Array<Array<PokerAction>>] The sequence of betting actions.
  def betting_sequence
    @betting_sequence ||= if @betting_sequence_string.empty?
      [[]]
    else
      lcl_betting_sequence = @betting_sequence_string.split(
        BETTING_SEQUENCE_SEPARATOR
      ).map do |betting_string_per_round|
        actions_from_acpc_characters(betting_string_per_round).map do |action|
          PokerAction.new(action)
        end
      end

      # Adjust the number of rounds if the last action was the last action in the round
      lcl_betting_sequence << [] if first_state_of_round?
      lcl_betting_sequence
    end
  end

  def community_cards
    @community_cards ||= -> do
      lcl_community_cards = BoardCards.new(
        all_sets_of_community_cards(@community_cards_string).map do |cards_in_round|
          Card.cards(cards_in_round)
        end
      )
      if lcl_community_cards.round < @community_cards_string.count(COMMUNITY_CARD_SEPARATOR)
        lcl_community_cards.next_round!
      end
      lcl_community_cards
    end.call
  end

  # @return [Integer] The zero indexed current round number.
  def round
    @round ||= @betting_sequence_string.count BETTING_SEQUENCE_SEPARATOR
  end

  # @return [Hand] The user's hand.
  # @example An ace of diamonds and a 4 of clubs is represented as
  #     'Ad4c'
  def hand
    @hand ||= all_hands[@position_relative_to_dealer]
  end

  # @return [Array] The list of opponent hole card hands.
  # @example If there are two opponents, one with AhKs and the other with QdJc, then
  #     list_of_opponents_hole_cards == [AhKs:Hand, QdJc:Hand]
  def opponent_hands
    @opponent_hands ||= -> do
      hands = all_hands.dup
      hands.delete_at @position_relative_to_dealer
      hands
    end.call
  end

  # @return [Boolean] Reports whether or not it is the first state of the first round.
  def first_state_of_first_round?
    @first_state_of_first_round ||= @betting_sequence_string.empty?
  end

  def first_state_of_round?
    @first_state_of_round ||= @betting_sequence_string[-1] == BETTING_SEQUENCE_SEPARATOR
  end

  # @return [Integer] The number of players in this match.
  def number_of_players
    @number_of_players ||= @hands_string.count(HAND_SEPARATOR) + 1
  end

  # @return [PokerAction] The last action taken.
  def last_action
    @last_action ||= if @betting_sequence_string.match(
      /([^#{BETTING_SEQUENCE_SEPARATOR}])#{BETTING_SEQUENCE_SEPARATOR}*$/
    )
      PokerAction.new($1)
    else
      nil
    end
  end

  # @return [Integer] The number of actions in the current round.
  def number_of_actions_this_round
    @number_of_actions_this_round ||= betting_sequence[round].length
  end

  # @return [Integer] The number of actions in the current hand.
  def number_of_actions_this_hand
    @number_of_actions_this_hand ||= betting_sequence.inject(0) do |sum, sequence_per_round|
      sum += sequence_per_round.length
    end
  end

  def round_in_which_last_action_taken
    @round_in_which_last_action_taken ||= if first_state_of_first_round?
      nil
    else
      if @betting_sequence_string[-1] == BETTING_SEQUENCE_SEPARATOR
        round - 1
      else
        round
      end
    end
  end

  # @param stacks [Array<#to_f>]
  # @param antes [Array<#to_f>]
  # @param first_player_positions [Array<Integer>] The positions relative
  # to the dealer that are first to act in each round, indexed from zero.
  # @param min_wagers [Array<#to_f>] The smallest wagers allowed in each round.
  # @return [Array<HandPlayer>] The current state of the players in this hand.
  def players(stacks, antes, first_player_positions, min_wagers)
    player_group(
      stacks,
      antes,
      first_player_positions,
      min_wagers,
      betting_sequence
    )
  end

  # def player_position_relative_to_self
  #   number_of_players - 1
  # end

  # def player_folded?(
  #   position_relative_to_dealer,
  #   first_player_positions
  # )
  # end

  # @param [Array<Integer>] first_player_positions List of first player positions
  #   relative to the dealer for each round.
  # @return [Array<Array<Integer>>]
  # def player_acting_sequence(first_player_positions)
    # sequence = []
    # player_activity = number_of_players.times.map { true }
    # betting_sequence.each_with_index do |actions_by_round, round|
    #   actions_by_round.each_with_index do |action, action_num|
    #     first_pos = first_player_positions[round]

    #     # @todo thing-to-do
    #     # acting_player = first_pos +

    #     if action == PokerAction::FOLD
    #       player_activity[acting_player] = false
    #     end
    #   end
    # end
  # end

  private

  def all_string_hands(string_of_card_sets)
    all_sets_of_cards(string_of_card_sets, HAND_SEPARATOR)
  end

  def all_sets_of_community_cards(string_of_card_sets)
    all_sets_of_cards(string_of_card_sets, COMMUNITY_CARD_SEPARATOR)
  end

  def all_sets_of_cards(string_of_card_sets, divider)
    string_of_card_sets.split(divider)
  end

  def actions_from_acpc_characters(action_sequence)
    action_sequence.scan(/[^#{BETTING_SEQUENCE_SEPARATOR}\d]\d*/)
  end
end

end