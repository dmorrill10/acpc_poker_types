require 'delegate'

require 'acpc_poker_types/board_cards'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/rank'
require 'acpc_poker_types/suit'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/hand_player'
require 'acpc_poker_types/hand_player_group'

module AcpcPokerTypes
module Indices
  refine Array do
    def inject_with_index(init)
      i = 0
      inject(init) do |accum, elem|
        yield accum, elem, i if block_given?
        i += 1
        accum
      end
    end
    def indices(elem_to_find=nil)
      if elem_to_find
        indices { |elem| elem == elem_to_find }
      else
        inject_with_index([]) do |array, elem, i|
          array << i if yield elem
          array
        end
      end
    end
  end
end
end
using AcpcPokerTypes::Indices

module AcpcPokerTypes

# Model to parse and manage information from a given match state string.
class MatchState < DelegateClass(String)
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

  attr_reader :hands_string

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
  def initialize(raw_match_state, previous_state = nil, game_def = nil)
    if (
      %r{#{LABEL}:(\d+):(\d+):([^:]*):([^#{COMMUNITY_CARD_SEPARATOR}\s]+)#{COMMUNITY_CARD_SEPARATOR}*([^\s:]*)}.match(
        raw_match_state
      )
    )
      @position_relative_to_dealer = $1.to_i
      @hand_number = $2.to_i
      @betting_sequence_string = $3
      @hands_string = $4
      @community_cards_string = $5
    end
    @str = nil
    @all_hands = nil
    @community_cards = nil
    @round = nil
    @hand = nil
    @opponent_hands = nil
    @first_state_of_first_round = nil
    @first_state_of_round = nil
    @last_action = nil
    @number_of_actions_this_round = nil
    @number_of_actions_this_hand = nil
    @round_in_which_last_action_taken = nil
    @number_of_players = nil
    @betting_sequence = nil
    @hand_ended = nil
    @opponents_cards_visible = nil
    @pot = nil
    @legal_actions = nil
    if (
      previous_state.nil? ||
      game_def.nil? ||
      last_action.nil? ||
      previous_state.number_of_actions_this_hand != number_of_actions_this_hand - 1
    )
      @precise_betting_sequence = nil
      @next_to_act = nil
      @players = nil
      @player_acting_sequence = nil
      @min_wager_by = nil
    else # Only process the one new action, bootstrapping from the given last state
      @precise_betting_sequence = previous_state.betting_sequence(game_def).map { |per_round| per_round.dup }
      @next_to_act = previous_state.next_to_act(game_def)
      @players = previous_state.players(game_def).dup
      @players.each_with_index { |player, i| player.hand = all_hands[i] }
      @player_acting_sequence = previous_state.player_acting_sequence(game_def).map { |per_round| per_round.dup }
      @min_wager_by = previous_state.min_wager_by(game_def)

      process_action!(last_action, round_in_which_last_action_taken)
      init_new_round!(game_def, round) if round != previous_state.round
      distribute_chips!(game_def) if hand_ended?(game_def)
    end

    super to_s
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

  # @return [Array<Hand>] The list of hole card hands for each player.
  def all_hands
    return @all_hands unless @all_hands.nil?

    @all_hands = all_string_hands(@hands_string).map do |string_hand|
      Hand.from_acpc string_hand
    end
    while @all_hands.length < number_of_players
      @all_hands.push Hand.new
    end
    @all_hands
  end

  # @param game_def [GameDefinition] A game definition by which the actions can be interpreted
  # and made more precise (bets marked by 'r' are converted into 'b' and checks marked by 'c'
  # are converted to 'k').
  # @return [Array<Array<PokerAction>>] The sequence of betting actions.
  def betting_sequence(game_def=nil)
    if game_def
      every_action(game_def) unless @precise_betting_sequence
      return @precise_betting_sequence
    end

    @betting_sequence ||= if @betting_sequence_string.empty?
      [[]]
    else
      sequence = @betting_sequence_string.split(
        BETTING_SEQUENCE_SEPARATOR
      ).map do |betting_string_per_round|
        actions_from_acpc_characters(betting_string_per_round).map do |action|
          PokerAction.new(action)
        end
      end

      # Adjust the number of rounds if the last action was the last action in the round
      while sequence.length <= round
        sequence << []
      end
      sequence
    end
  end

  # @return [BoardCards] All visible community cards on the board.
  def community_cards
    return @community_cards unless @community_cards.nil?

    @community_cards = BoardCards.new(
      all_sets_of_community_cards(@community_cards_string).map do |cards_per_round|
        Card.cards(cards_per_round)
      end
    )
    if @community_cards.round < @community_cards_string.count(COMMUNITY_CARD_SEPARATOR)
      @community_cards.next_round!
    end
    @community_cards
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
    return @opponent_hands unless @opponent_hands.nil?

    @opponent_hands = all_hands.dup
    @opponent_hands.delete_at @position_relative_to_dealer
    @opponent_hands
  end

  # @return [Boolean] Reports whether or not it is the first state of the first round.
  def first_state_of_first_round?
    return @first_state_of_first_round unless @first_state_of_first_round.nil?

    @first_state_of_first_round = @betting_sequence_string.empty?
  end

  def first_state_of_round?
    return @first_state_of_round unless @first_state_of_round.nil?

    @first_state_of_round = @betting_sequence_string[-1] == BETTING_SEQUENCE_SEPARATOR
  end

  # @return [Integer] The number of players in this match.
  def number_of_players
    @number_of_players ||= @hands_string.count(HAND_SEPARATOR) + 1
  end

  # @return [PokerAction] The last action taken.
  def last_action
    @last_action ||= if betting_sequence.flatten.empty?
      nil
    else
      betting_sequence[round_in_which_last_action_taken].last
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
  # @param blinds [Array<#to_f>]
  # @return [HandPlayerGroup] The state of the players in this hand at the
  # when the hand began.
  def players_at_hand_start(stacks, blinds)
    HandPlayerGroup.new all_hands, stacks, blinds
  end

  # @param game_def [GameDefinition]
  # @return [HandPlayerGroup] The current state of the players.
  def every_action(game_def)
    @players = players_at_hand_start game_def.chip_stacks, game_def.blinds

    @next_to_act = game_def.first_player_positions.first
    @player_acting_sequence = []
    @precise_betting_sequence = []
    @min_wager_by = game_def.min_wagers.first

    walk_over_betting_sequence!(game_def)

    distribute_chips!(game_def) if hand_ended?(game_def)

    @players
  end

  def next_to_act(game_def)
    every_action(game_def) unless @next_to_act

    @next_to_act
  end

  def players(game_def)
    @players ||= every_action(game_def)
  end

  def player_acting_sequence(game_def)
    every_action(game_def) unless @player_acting_sequence

    @player_acting_sequence
  end

  # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
  def hand_ended?(game_def)
    return @hand_ended unless @hand_ended.nil?

    @hand_ended = (
      reached_showdown? ||
      players(game_def).count { |player| player.folded? } >= number_of_players - 1
    )
  end

  def reached_showdown?
    opponents_cards_visible?
  end

  def opponents_cards_visible?
    return @opponents_cards_visible unless @opponents_cards_visible.nil?

    @opponents_cards_visible = all_hands.count { |h| !h.empty? } > 1 # At least one opponent hand visible
  end

  def pot(game_def)
    @pot ||= players(game_def).map { |player| player.contributions }.flatten.inject(:+)
  end

  # @return [ChipStack] Minimum wager by.
  def min_wager_by(game_def)
    every_action(game_def) if @min_wager_by.nil?

    @min_wager_by
  end

  # @return [Array<PokerAction>] The legal actions for the next player to act.
  def legal_actions(game_def)
    return [] unless next_to_act(game_def)
    return @legal_actions unless @legal_actions.nil?

    @legal_actions = players(game_def).legal_actions(
      next_to_act(game_def),
      round,
      game_def,
      min_wager_by(game_def)
    )
  end

  private

  def walk_over_betting_sequence!(game_def)
    betting_sequence.each_with_index do |actions_per_round, current_round|
      init_new_round!(game_def, current_round)

      walk_over_actions!(actions_per_round, current_round)
    end

    self
  end

  def init_new_round!(game_def, current_round)
    @min_wager_by = game_def.min_wagers[current_round]
    @next_to_act = @players.position_of_first_active_player(
      game_def.first_player_positions[current_round]
    )
    while @player_acting_sequence.length <= current_round
      @player_acting_sequence << []
      @precise_betting_sequence << []
    end

    self
  end

  def walk_over_actions!(actions_per_round, current_round)
    actions_per_round.each do |action|
      process_action!(action, current_round)

      yield(
        @precise_betting_sequence[current_round].last,
        current_round,
        @player_acting_sequence[current_round].last
      ) if block_given?
    end

    self
  end

  def process_action!(action, current_round)
    cost = @players.action_cost(
      @next_to_act,
      action,
      @min_wager_by
    )

    @precise_betting_sequence[current_round] << PokerAction.new(
      action.to_s(
        pot_gained_chips: @players.inject(0) { |sum, player| sum += player.contributions[current_round].to_i } > 0,
        player_sees_wager: @players.amount_to_call(@next_to_act) > 0
      ),
      cost: cost
    )

    adjust_min_wager!(
      @precise_betting_sequence[current_round].last,
      @next_to_act
    )

    @players[@next_to_act].append_action!(
      @precise_betting_sequence[current_round].last, current_round
    )

    @player_acting_sequence[current_round] << @next_to_act
    @next_to_act = @players.next_to_act(@next_to_act)

    self
  end

  # Distribute chips to all winning players
  def distribute_chips!(game_def)
    return self if pot(game_def) <= 0

    # @todo This only works for Doyle's game where there are no side-pots.
    if 1 == players(game_def).count { |player| !player.folded? }
      players(game_def).select { |player| !player.folded? }.first.winnings = pot(game_def)
    else
      hand_strengths = players(game_def).map do |player|
        if player.folded?
          -1
        else
          PileOfCards.new(community_cards.flatten + player.hand).to_poker_hand_strength
        end
      end
      winning_players = hand_strengths.indices(hand_strengths.max)
      amount_each_player_wins = pot(game_def)/winning_players.length.to_r

      winning_players.each do |player_index|
        @players[player_index].winnings = amount_each_player_wins
      end
    end

    self
  end

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

  def adjust_min_wager!(action, acting_player_position)
    return self unless PokerAction::MODIFIABLE_ACTIONS.include?(action.action)

    wager_size = ChipStack.new(
      action.cost.to_f - @players.amount_to_call(acting_player_position)
    )

    return self unless wager_size > @min_wager_by

    @min_wager_by = wager_size

    self
  end
end
end