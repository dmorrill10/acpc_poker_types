
# Local modules
require File.expand_path('../board_cards', __FILE__)
require File.expand_path('../hand', __FILE__)
require File.expand_path('../../acpc_poker_types_defs', __FILE__)
require File.expand_path('../../helpers/acpc_poker_types_helper', __FILE__)
require File.expand_path('../rank', __FILE__)
require File.expand_path('../suit', __FILE__)
require File.expand_path('../poker_action', __FILE__)

# Local mixins
require File.expand_path('../../mixins/utils', __FILE__)

# Model to parse and manage information from a given match state string.
class MatchStateString
   include AcpcPokerTypesDefs
   include AcpcPokerTypesHelper
   
   exceptions :incomplete_match_state_string
   
   alias_new :parse
   
   # Builds a match state string from its given component parts.
   #
   # @param [#to_s] position_relative_to_dealer The position relative to the dealer.
   # @param [#to_s] hand_number The hand number.
   # @param [#to_s] betting_sequence The betting sequence.
   # @param [#to_s] all_hole_cards All the hole cards visible.
   # @param [#to_s, #empty?] board_cards All the community cards on the board.
   # @return [String] The constructed match state string.
   def self.build_match_state_string(position_relative_to_dealer,
                                     hand_number, betting_sequence,
                                     all_hole_cards, board_cards)
      string = MATCH_STATE_LABEL +
      ":#{position_relative_to_dealer}:#{hand_number}:#{betting_sequence}:#{all_hole_cards}"
      
      string += "#{board_cards}" if board_cards and !board_cards.empty?
      string
   end
   
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
   
   # @return [Array<Array<PokerAction>>] The sequence of betting actions.
   attr_reader :betting_sequence
   
   # @return [Array<Hand>] The list of visible hole card sets for each player.
   attr_reader :list_of_hole_card_hands
   
   # @return [BoardCards] All visible community cards on the board.
   attr_reader :board_cards
   
   # @return [Array<Integer>] The list of first seats for each round.
   attr_reader :first_seat_in_each_round
   
   # @param [String] raw_match_state A raw match state string to be parsed.
   # @raise IncompleteMatchStateString
   def initialize(raw_match_state)
      raise IncompleteMatchStateString, raw_match_state if line_is_comment_or_empty? raw_match_state
      
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join
      all_ranks = CARD_RANKS.values.join
      all_suits = (CARD_SUITS.values.map { |suit| suit[:acpc_character] }).join
      all_card_tokens = all_ranks + all_suits
      
      if raw_match_state.match(
         /#{MATCH_STATE_LABEL}:(\d+):(\d+):([\d#{all_actions}\/]*):([|#{all_card_tokens}]+)\/*([\/#{all_card_tokens}]*)/)
         @position_relative_to_dealer = $1.to_i
         @hand_number = $2.to_i
         @betting_sequence = parse_betting_sequence $3
         @list_of_hole_card_hands = parse_list_of_hole_card_hands $4
         @board_cards = parse_board_cards $5
      end
      
      raise IncompleteMatchStateString, raw_match_state if incomplete_match_state?
   end

   # @return [String] The MatchStateString in raw text form.
   def to_str      
      MatchStateString.build_match_state_string @position_relative_to_dealer,
         @hand_number, betting_sequence_string,
         hole_card_strings(@list_of_hole_card_hands), @board_cards
   end
   
   # @see to_str
   alias_method :to_s, :to_str
   
   # @param [MatchStateString] another_match_state_string A matchstate string to compare against this one.
   # @return [Boolean] +true+ if this matchstate string is equivalent to +another_match_state_string+, +false+ otherwise.
   def ==(another_match_state_string)
      another_match_state_string.to_s == to_s
   end
   
   # @return [Integer] The number of players in this match.
   def number_of_players() @list_of_hole_card_hands.length end
   
   # @param [Array<Array<PokerAction>>] betting_sequence The betting sequence from which the last action should be retrieved.
   # @return [PokerAction, NilClass] The last action taken or +nil+ if no action was previously taken.
   def last_action(betting_sequence=@betting_sequence)
      last_action_in_the_current_round = betting_sequence.last.last
      if !last_action_in_the_current_round && round > 0
         return betting_sequence[-2].last
      end
      last_action_in_the_current_round
   end

   # @return [Hand] The user's hole cards.
   # @example An ace of diamonds and a 4 of clubs is represented as
   #     'Ad4c'
   def users_hole_cards
      list_of_hole_card_hands[@position_relative_to_dealer]
   end
   
   # @return [Array] The list of opponent hole cards that are visible.
   # @example If there are two opponents, one with AhKs and the other with QdJc, then
   #     list_of_opponents_hole_cards == [AhKs:Hand, QdJc:Hand]
   def list_of_opponents_hole_cards
      local_list_of_hole_card_hands = list_of_hole_card_hands.dup
      local_list_of_hole_card_hands.delete_at @position_relative_to_dealer
      local_list_of_hole_card_hands
   end
   
   # @return [Integer] The zero indexed current round number.
   def round
      @betting_sequence.length - 1
   end
   
   # @return [Integer] The number of actions in the current round.
   def number_of_actions_in_current_round() @betting_sequence[round].length end
   
   # @param [Array<Action>] betting_sequence=@betting_sequence The sequence of
   #  actions to link into an ACPC string.
   # @return [String] The ACPC string created by the given betting sequence, +betting_sequence+.
   def betting_sequence_string(betting_sequence=@betting_sequence)
      string = ''
      (round + 1).times do |i|
         string += (betting_sequence[i].map { |action| action.to_acpc }).join('')
         string += '/' unless i == round
      end
      string
   end
   
   # @return [Bool] Reports whether or not it is the first state of the first round.
   def first_state_of_the_first_round?
      0 == round && 0 == number_of_actions_in_current_round
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
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join ''
      betting_sequence.scan(/[#{all_actions}]\d*/)
   end
   
   def incomplete_match_state?
      !(@position_relative_to_dealer and @hand_number and
        @list_of_hole_card_hands) || @list_of_hole_card_hands.empty?
   end
   
   def parse_list_of_hole_card_hands(string_of_hole_cards)      
      list_of_hole_card_hands = []
      for_every_set_of_cards(string_of_hole_cards, '\|') do |string_hand|
         hand = Hand.draw_cards string_hand
         list_of_hole_card_hands.push hand
      end
      while list_of_hole_card_hands.length < (string_of_hole_cards.count('|') + 1)
         list_of_hole_card_hands.push ''
      end
      list_of_hole_card_hands
   end
   
   def parse_betting_sequence(string_betting_sequence, acting_player_sees_wager=true)
      return [[]] if string_betting_sequence.empty?
      
      list_of_actions_by_round = string_betting_sequence.split(/\//)
      betting_sequence = list_of_actions_by_round.inject([]) do |list_of_actions, betting_string_in_a_particular_round|
         list_of_actions_in_a_particular_round = list_of_actions_from_acpc_characters(betting_string_in_a_particular_round).inject([]) do |list, action|
            list.push PokerAction.new(action)
         end
         list_of_actions.push list_of_actions_in_a_particular_round
      end
      # Increase the resolution of the last action
      # @todo I'm creating one too many PokerActions, but I'm not going to worry about it for now.
      betting_sequence[-1][-1] = PokerAction.new(last_action(betting_sequence).to_acpc_character, last_action(betting_sequence).modifier, acting_player_sees_wager)
      
      # Adjust the number of rounds if the last action was the last action in the round
      if string_betting_sequence.match(/\//)
         betting_sequence << [] if string_betting_sequence.count('/') > (betting_sequence.length - 1)
      end
      betting_sequence
   end
   
   def parse_board_cards(string_board_cards)
      board_cards = BoardCards.new
      for_every_set_of_cards(string_board_cards, '\/') do |string_board_card_set|
         next if string_board_card_set.match(/^\s*$/)
         for_every_card(string_board_card_set) do |card|
            board_cards << card
         end
         board_cards.next_round! if board_cards.round < string_board_cards.count('/')
      end
      board_cards
   end
   
   def for_every_set_of_cards(string_of_card_sets, divider)
      string_of_card_sets.split(/#{divider}/).each do |string_card_set|
         yield string_card_set
      end
   end
   
   def for_every_card(string_of_cards)
      all_ranks = CARD_RANKS.values.join
      all_suits = (CARD_SUITS.values.map { |suit| suit[:acpc_character] }).join
      
      string_of_cards.scan(/[#{all_ranks}][#{all_suits}]/).each do |string_card|        
         card = Card.new string_card
         yield card
      end
   end
   
   def hole_card_strings(list_of_hole_card_hands)      
      (list_of_hole_card_hands.map { |hand| hand.to_s }).join '|'
   end
end
