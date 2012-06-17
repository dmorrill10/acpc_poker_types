require File.expand_path("../acpc_poker_types/version", __FILE__)

module AcpcPokerTypes
   # @return [String] Label for match state strings.
   MATCH_STATE_LABEL = 'MATCHSTATE'
   
   # @return [Hash] Maximum game parameter values.
   MAX_VALUES = {
      :rounds => 4, 
      :players => 10, 
      :board_cards => 7, 
      :hole_cards => 3, 
      :number_of_actions => 64,
      :line_length => 1024
   }

   # @return [Hash] Betting types understood by this application.
   BETTING_TYPES = {
      :limit => 'limit', 
      :nolimit => 'nolimit'
   }
   
   # @return [Hash] Numeric representation of each action type.
   ACTION_TYPE_NUMBERS = {
      'f' => 0,
      'c' => 1,
      'r' => 2
   }

   # @return [Array] A list of all the hole cards understood by this application.
   LIST_OF_HOLE_CARD_HANDS =
           LIST_OF_CARDS.map {|first_card| LIST_OF_CARDS.map {|second_card| first_card + second_card}}.flatten

   # @return [Integer] The maximum value of an eight bit unsigned integer (for consistency with the ACPC dealer).
   UINT8_MAX = 2**8 - 1

   # @return [Integer] The maximum value of a 32 bit signed integer (for consistency with the ACPC dealer).
   INT32_MAX = 2**31 - 1

   # @return [String] A newline character.
   NEWLINE = "\n"
   
   # @return [Array] The default first player position in each round.
   DEFAULT_FIRST_PLAYER_POSITION_IN_EVERY_ROUND = MAX_VALUES[:rounds].times.inject([]) { |list, i| list << 1 }
   
   # @return [Array] The default maximum raise in each round.
   DEFAULT_MAX_NUMBER_Of_WAGERS = MAX_VALUES[:rounds].times.inject([]) { |list, i|  list << UINT8_MAX }
   
   # @return [Hash<Symbol, String>] File names of the game definitions understood by this application.
   GAME_DEFINITION_FILE_NAMES = lambda do
      path_to_project_acpc_server_directory = File.expand_path('../../../ext/project_acpc_server', __FILE__)
      
      {
         holdem_limit_2p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.limit.2p.reverse_blinds.game",
         holdem_no_limit_2p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.nolimit.2p.reverse_blinds.game",
         holdem_limit_3p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.limit.3p.game",
         holdem_no_limit_3p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.nolimit.3p.game"
      }
   end.call

   # @param [Integer] number_of_players The number of players that require stacks.
   # @return [Array] The default list of initial stacks for every player.
   def default_chip_stacks(number_of_players)
      list_of_player_stacks = []
      number_of_players.times do
         list_of_player_stacks << AcpcPokerTypesDefs::INT32_MAX
      end
      list_of_player_stacks
   end
   
   # @yield [Card, Card] Iterate through every permutation of cards in the deck.
   # @yieldparam (see #for_every_rank_and_suit_in_the_deck)
   def for_every_list_of_two_cards_in_the_deck
      for_every_rank_and_suit_in_the_deck do |rank_1, suit_1|
         for_every_rank_and_suit_in_the_deck do |rank_2, suit_2|
            card_1 = Card.new rank_1, suit_1
            card_2 = Card.new rank_2, suit_2
            
            yield card_1, card_2
         end
      end
   end
   
   # @yield [Card] Iterate through every recognized card.
   # @yieldparam (see #for_every_rank_and_suit_in_the_deck)
   def for_every_card_in_the_deck
      for_every_rank_and_suit_in_the_deck do |rank, suit|
         yield Card.new rank, suit
      end
   end
   
   # @yield [Symbol, Symbol] Iterate through every combination of ranks and suits in the deck.
   # @yieldparam (see #for_every_suit_in_the_deck)
   # @yieldparam (see #for_every_rank_in_the_deck)
   def for_every_rank_and_suit_in_the_deck
      for_every_rank_in_the_deck do |rank|
         for_every_suit_in_the_deck do |suit|   
            yield rank, suit
         end
      end
   end
   
   # @yield [Symbol] Iterate through every recognized rank.
   # @yieldparam [Symbol] rank The rank of the card.
   def for_every_rank_in_the_deck
      AcpcPokerTypesDefs::CARD_RANKS.keys.each { |rank| yield rank }
   end
   
   # @yield [Symbol] Iterate through every recognized suit.
   # @yieldparam [Symbol] suit The suit of the card.
   def for_every_suit_in_the_deck
      AcpcPokerTypesDefs::CARD_SUITS.keys.each { |suit| yield suit }
   end
   
   # Flatten a given array into a single element if there is only one element in the array.
   # That is, if the given array is a single element array, it returns that element,
   # otherwise it returns the array.
   #
   # @param [Array] array The array to flatten into a single element.
   # @return +array+ if +array+ has more than one element, the single element in +array+ otherwise.
   def flatten_if_single_element_array(array)
      if 1 == array.length then array[0] else array end
   end

   # Loops over every line in the file corresponding to the given file name.
   #
   # @param [String] file_name The name of the file to loop through.
   # @yield Block to operate on +line+.
   # @yieldparam [String] line A line from the file corresponding to +file_name+.
   # @raise [Errno::ENOENT] Unable to open or read +file_name+ error.
   def for_every_line_in_file(file_name)
      begin
         file = File.new file_name, "r"
      rescue
         raise "Unable to open #{file_name}"
      else         
         begin
            while line = file.gets do
               line.chomp!
               
               yield line
            end
         rescue Errno::ENOENT => e
            raise e, "Unable to read #{file_name}: #{e.message}"
         end
      ensure
         file.close if file
      end
   end

   # Checks if the given line is a comment beginning with '#' or ';', or empty.
   #
   # @param [String] line
   # @return [Boolean] True if +line+ is a comment or empty, false otherwise.
   def line_is_comment_or_empty?(line)
      return true unless line
      !line.match(/^\s*[#;]/).nil? or line.empty?
   end
end

require File.expand_path("../hand_evaluator", __FILE__)
require File.expand_path("../acpc_poker_types/board_cards", __FILE__)
require File.expand_path("../acpc_poker_types/card", __FILE__)
require File.expand_path("../acpc_poker_types/chip_stack", __FILE__)
require File.expand_path("../acpc_poker_types/game_definition", __FILE__)
require File.expand_path("../acpc_poker_types/hand", __FILE__)
require File.expand_path("../acpc_poker_types/match_state_string", __FILE__)
require File.expand_path("../acpc_poker_types/pile_of_cards", __FILE__)
require File.expand_path("../acpc_poker_types/player", __FILE__)
require File.expand_path("../acpc_poker_types/pot", __FILE__)
require File.expand_path("../acpc_poker_types/rank", __FILE__)
require File.expand_path("../acpc_poker_types/side_pot", __FILE__)
require File.expand_path("../acpc_poker_types/suit", __FILE__)
