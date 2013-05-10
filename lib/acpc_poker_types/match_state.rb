require 'acpc_poker_types/board_cards'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/rank'
require 'acpc_poker_types/suit'
require 'acpc_poker_types/poker_action'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# Model to parse and manage information from a given match state string.
module AcpcPokerTypes
  class MatchState
    exceptions :incomplete_match_state

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

    # @return [Array<Array<AcpcPokerTypes::PokerAction>>] The sequence of betting actions.
    attr_reader :betting_sequence

    # @return [Array<AcpcPokerTypes::Hand>] The list of visible hole card sets for each player.
    attr_reader :list_of_hole_card_hands

    # @return [AcpcPokerTypes::BoardCards] All visible community cards on the board.
    attr_reader :board_cards

    # @return [Array<Integer>] The list of first seats for each round.
    attr_reader :first_seat_in_each_round

    # @return [String] Label for match state strings.
    LABEL = 'MATCHSTATE'

    class << self; alias_method(:parse, :new) end

    # Builds a match state string from its given component parts.
    #
    # @param [#to_s] position_relative_to_dealer The position relative to the dealer.
    # @param [#to_s] hand_number The hand number.
    # @param [#to_s] betting_sequence The betting sequence.
    # @param [#to_s] all_hole_cards All the hole cards visible.
    # @param [#to_acpc, #empty?] board_cards All the community cards on the board.
    # @return [String] The constructed match state string.
    def self.build_match_state_string(
      position_relative_to_dealer,
      hand_number,
      betting_sequence,
      all_hole_cards,
      board_cards
    )
      string = "#{LABEL}:#{position_relative_to_dealer}:#{hand_number}:#{betting_sequence}:#{all_hole_cards}"
      string << board_cards.to_acpc if board_cards && !board_cards.empty?
      string
    end

    # Checks if the given line is a comment beginning with '#' or ';', or empty.
    #
    # @param [String] line
    # @return [Boolean] True if +line+ is a comment or empty, false otherwise.
    def self.line_is_comment_or_empty?(line)
      line.nil? || line.match(/^\s*[#;]/) || line.empty?
    end

    # @param [String] raw_match_state A raw match state string to be parsed.
    # @raise IncompleteMatchState
    def initialize(raw_match_state)
      raise IncompleteMatchState, raw_match_state if AcpcPokerTypes::MatchState.line_is_comment_or_empty? raw_match_state

      if raw_match_state.match(
        /#{LABEL}:(\d+):(\d+):([\d#{AcpcPokerTypes::PokerAction::CONCATONATED_ACTIONS}\/]*):([|#{AcpcPokerTypes::Card::CONCATONATED_CARDS}]+)\/*([\/#{AcpcPokerTypes::Card::CONCATONATED_CARDS}]*)/)
        @position_relative_to_dealer = $1.to_i
        @hand_number = $2.to_i
        @betting_sequence = parse_betting_sequence $3
        @list_of_hole_card_hands = parse_list_of_hole_card_hands $4
        @board_cards = parse_board_cards $5
      end

      raise IncompleteMatchState, raw_match_state if incomplete_match_state?
    end

    # @return [String] The AcpcPokerTypes::MatchState in raw text form.
    def to_str
      AcpcPokerTypes::MatchState.build_match_state_string(
        @position_relative_to_dealer,
        @hand_number, betting_sequence_string,
        hole_card_strings,
        @board_cards
      )
    end

    # @see to_str
    alias_method :to_s, :to_str

    # @param [AcpcPokerTypes::MatchState] another_match_state A match state string to compare against this one.
    # @return [Boolean] +true+ if this match state string is equivalent to +another_match_state+, +false+ otherwise.
    def ==(another_match_state)
      another_match_state.to_s == to_s
    end

    # @return [Integer] The number of players in this match.
    def number_of_players() @list_of_hole_card_hands.length end

    # @param [Array<Array<AcpcPokerTypes::PokerAction>>] betting_sequence The betting sequence from which the last action should be retrieved.
    # @return [AcpcPokerTypes::PokerAction] The last action taken.
    # @raise NoActionsHaveBeenTaken if no actions have been taken.
    def last_action(betting_sequence=@betting_sequence)
      if betting_sequence.nil? || betting_sequence.empty?
        nil
      elsif betting_sequence.last.last
        betting_sequence.last.last
      else
        last_action(betting_sequence.reject{ |elem| elem.equal?(betting_sequence.last) })
      end
    end

    # @return [AcpcPokerTypes::Hand] The user's hole cards.
    # @example An ace of diamonds and a 4 of clubs is represented as
    #     'Ad4c'
    def users_hole_cards
      @list_of_hole_card_hands[@position_relative_to_dealer]
    end

    # @return [Array] The list of opponent hole cards that are visible.
    # @example If there are two opponents, one with AhKs and the other with QdJc, then
    #     list_of_opponents_hole_cards == [AhKs:AcpcPokerTypes::Hand, QdJc:AcpcPokerTypes::Hand]
    def list_of_opponents_hole_cards
      local_list_of_hole_card_hands = @list_of_hole_card_hands.dup
      local_list_of_hole_card_hands.delete_at @position_relative_to_dealer
      local_list_of_hole_card_hands
    end

    # @return [Integer] The zero indexed current round number.
    def round
      @betting_sequence.length - 1
    end

    # @return [Integer] The number of actions in the current round.
    def number_of_actions_this_round() @betting_sequence[round].length end

    # @return [Integer] The number of actions in the current hand.
    def number_of_actions_this_hand
      @betting_sequence.inject(0) do |sum, sequence_per_round|
        sum += sequence_per_round.length
      end
    end

    # @param [Array<Action>] betting_sequence=@betting_sequence The sequence of
    #  actions to link into an ACPC string.
    # @return [String] The ACPC string created by the given betting sequence,
    #  +betting_sequence+.
    def betting_sequence_string(betting_sequence=@betting_sequence)
      (round + 1).times.inject('') do |string, i|
        string << (betting_sequence[i].map { |action| action.to_s }).join('')
        string << '/' unless i == round
        string
      end
    end

    # @return [Boolean] Reports whether or not it is the first state of the first round.
    def first_state_of_first_round?
      (0 == number_of_actions_this_hand)
    end

    def player_position_relative_to_self
      number_of_players - 1
    end

    def round_in_which_last_action_taken
      unless number_of_actions_this_hand > 0
        nil
      else
        if number_of_actions_this_round < 1
          round - 1
        else
          round
        end
      end
    end

    private

    def validate_first_seats(list_of_first_seats)
      begin
        raise UnknownFirstSeat, round unless round < list_of_first_seats.length
        all_seats_are_occupied = ((problem_seat = list_of_first_seats.max) < number_of_players) && ((problem_seat = list_of_first_seats.min.abs)-1 < number_of_players)
        raise FirstSeatIsUnoccupied, problem_seat unless all_seats_are_occupied
      rescue UnknownFirstSeat => e
        raise e
      rescue FirstSeatIsUnoccupied => e
        raise e
      rescue => e
        raise UnknownFirstSeat, e.message
      end
      list_of_first_seats
    end

    def list_of_actions_from_acpc_characters(betting_sequence)
      betting_sequence.scan(/[#{AcpcPokerTypes::PokerAction::CONCATONATED_ACTIONS}]\d*/)
    end

    def incomplete_match_state?
      !(@position_relative_to_dealer and @hand_number and
        @list_of_hole_card_hands) || @list_of_hole_card_hands.empty?
    end

    def parse_list_of_hole_card_hands(string_of_hole_cards)
      list_of_hole_card_hands = every_set_of_cards(string_of_hole_cards, '\|').map do |string_hand|
        AcpcPokerTypes::Hand.from_acpc string_hand
      end
      while list_of_hole_card_hands.length < (string_of_hole_cards.count('|') + 1)
        list_of_hole_card_hands.push AcpcPokerTypes::Hand.new
      end
      list_of_hole_card_hands
    end

    def parse_betting_sequence(string_betting_sequence)
      return [[]] if string_betting_sequence.empty?

      betting_sequence = string_betting_sequence.split(/\//).map do |betting_string_per_round|
        list_of_actions_in_a_particular_round = list_of_actions_from_acpc_characters(
          betting_string_per_round
        ).map do |action|
          AcpcPokerTypes::PokerAction.new(action)
        end
      end

      # Adjust the number of rounds if the last action was the last action in the round
      betting_sequence << [] if string_betting_sequence.match(/\/$/)
      betting_sequence
    end

    def parse_board_cards(string_board_cards)
      board_cards = AcpcPokerTypes::BoardCards.new(
        every_set_of_cards(string_board_cards, '\/').map do |cards_in_round|
          AcpcPokerTypes::Card.cards(cards_in_round)
        end
      )
      board_cards.next_round! if board_cards.round < string_board_cards.count('/')
      board_cards
    end

    def every_set_of_cards(string_of_card_sets, divider)
      string_of_card_sets.split(/#{divider}/)
    end

    def hole_card_strings
      (@list_of_hole_card_hands.map { |hand| hand.to_acpc }).join '|'
    end
  end
end