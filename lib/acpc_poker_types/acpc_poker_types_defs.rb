
# Assortment of definitions for poker types.
module AcpcPokerTypesDefs
   # @return [String] Label for match state strings.
   MATCH_STATE_LABEL = 'MATCHSTATE'
   
   # @return [Hash] Maximum game parameter values.
   MAX_VALUES = {:rounds => 4, :players => 10, :board_cards => 7, :hole_cards => 3, :number_of_actions => 64,
                 :line_length => 1024}

   # @return [Hash] Betting types understood by this application.
   BETTING_TYPES = {:limit => 'limit', :nolimit => 'nolimit'}
   
   # @return [Hash] Numeric representation of each action type.
   ACTION_TYPE_NUMBERS = {'f' => 0, 'c' => 1, 'r' => 2}
   
   # @return [Hash] Card ranks understood by this application.
   CARD_RANKS = {:two => '2', :three => '3', :four => '4', :five => '5', :six => '6', :seven => '7', :eight => '8',
                 :nine => '9', :ten => 'T', :jack => 'J', :queen => 'Q', :king => 'K', :ace => 'A'}
   
   # @return [Hash] Numeric representation of each card rank (though not the
   #     numeric version of the rank).
   # @example The numeric representation of rank +'2'+ is +0+, not +2+.
   #     CARD_RANK_NUMBERS['2'] == 0
   CARD_RANK_NUMBERS = {'2' => 0, '3' => 1, '4' => 2, '5' => 3, '6' => 4,
      '7' => 5, '8' => 6, '9' => 7, 'T' => 8, 'J' => 9, 'Q' => 10, 'K' => 11,
      'A' => 12}

   # @return [Hash<Symbol, Hash>] Card suits understood by this application.
   CARD_SUITS = {spades: {acpc_character: 's', html_character: '&spades;'},
      hearts: {acpc_character: 'h', html_character: '&hearts;'},
      diamonds: {acpc_character: 'd', html_character: '&diams;'},
      clubs: {acpc_character: 'c', html_character: '&clubs;'}}
   
   ACPC_SUIT_CHARACTERS_TO_CARD_SUIT_SYMBOLS = CARD_SUITS.inject({}) do |new_relation, suit_relation_array|
      acpc_character = suit_relation_array[1][:acpc_character]
      symbol = suit_relation_array[0]
      new_relation[acpc_character] = symbol
      new_relation
   end
   
   # @return [Hash] Numeric representation of each card suit.
   CARD_SUIT_NUMBERS = {'c' => 0, 'd' => 1, 'h' => 2, 's' => 3}
   
   # @return [Array] A list of all the cards understood by this application.
   LIST_OF_CARDS = (CARD_RANKS.values.map {|rank| CARD_SUITS.values.map {|suit| rank + suit[:acpc_character]}}).flatten

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
   DEFAULT_MAX_RAISE_IN_EACH_ROUND = MAX_VALUES[:rounds].times.inject([]) { |list, i|  list << UINT8_MAX }
   
   # @return [Hash<Symbol, String>] File names of the game definitions understood by this application.
   GAME_DEFINITION_FILE_NAMES = lambda do
      path_to_project_acpc_server_directory = File.expand_path('../../../ext/project_acpc_server', __FILE__)
      
      {holdem_limit_2p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.limit.2p.reverse_blinds.game",
         holdem_no_limit_2p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.nolimit.2p.reverse_blinds.game",
         holdem_limit_3p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.limit.3p.game",
         holdem_no_limit_3p_reverse_blinds_game: "#{path_to_project_acpc_server_directory}/holdem.nolimit.3p.game"}
   end.call
end
