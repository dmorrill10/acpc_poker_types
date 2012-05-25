
# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)
require File.expand_path('../../helpers/acpc_poker_types_helper', __FILE__)

# Local mixins
require File.expand_path('../../mixins/utils', __FILE__)

# Class that parses and manages game definition information from a game definition file.
class GameDefinition
   include AcpcPokerTypesDefs
   include AcpcPokerTypesHelper
   
   singleton_class.send(:include, AcpcPokerTypesHelper)
   
   exceptions :game_definition_parse_error
      
   # @return [String] The string designating the betting type.
   attr_reader :betting_type
   
   # @return [Integer] The number of players.
   attr_reader :number_of_players
      
   # @return [Integer] The number of rounds.
   attr_reader :number_of_rounds
      
   # @return [Array] The number of board cards in each round.
   # @example The usual Texas hold'em sequence would look like this:
   #     number_of_board_cards == [0, 3, 1, 1]
   attr_reader :number_of_board_cards
      
   # @return [Array] The minimum wager in each round.
   attr_reader :min_wagers
      
   # @return [Array] The position relative to the dealer that is first to act
   #     in each round, indexed from 1.
   # @example The usual Texas hold'em sequence would look like this:
   #     first_player_positions == [2, 1, 1, 1]
   attr_reader :first_player_positions
   
   # @return [Array] The maximum number of wagers in each round.
   attr_reader :max_number_of_wagers
   
   # @return [Array] The list containing the initial stack size for every player.
   attr_reader :chip_stacks
   
   # @return [Integer] The number of suits in the deck.
   attr_reader :number_of_suits
   
   # @return [Integer] The number of ranks in the deck.
   attr_reader :number_of_ranks
   
   # @return [Integer] The number of hole cards that each player is dealt.
   attr_reader :number_of_hole_cards
   
   # @return [Array] The list of blind sizes.
   attr_reader :blinds
   
   # Checks a given line from a game definition file for a game
   # definition name and returns the given default value unless there is a match.
   #
   # @param [String, #match] line A line from a game definition file.
   # @param [String] definition_name The name of the game definition that is
   #     being checked for in +line+.
   # @param default The default value to return in the case that the game
   #     definition name doesn't match +line+.
   # @return The game definition value in +line+ if +line+ contains the game definition
   #     referred to by +definition_name+, +default+ otherwise.
   def self.check_game_def_line_for_definition(line, definition_name, default)
      if line.match(/^\s*#{definition_name}\s*=\s*([\d\s]+)/i)
         values = $1.chomp.split(/\s+/)
         (0..values.length-1).each do |i|
            values[i] = values[i].to_i
         end
         return flatten_if_single_element_array values
      end
      
      default
   end

   # Checks if the given line from a game definition file is informative or not
   # (in which case the line is either: a comment beginning with '#', empty, or
   # contains 'gamedef').
   #
   # @return [String] line The line to check.
   # @return [Boolean] +true+ if the line is not informative, +false+ otherwise.
   def self.game_def_line_not_informative?(line)
      line_is_comment_or_empty?(line) || line.match(/\s*gamedef\s*/i)
   end

   # @param [String] game_definition_file_name The name of the game definition file that this instance should parse.
   # @raise GameDefinitionParseError
   def initialize(game_definition_file_name)
      initialize_members!
      begin
         parse_game_definition! game_definition_file_name
      rescue => unable_to_read_or_open_file_error
         raise GameDefinitionParseError, unable_to_read_or_open_file_error.message
      end
      
      @chip_stacks = default_chip_stacks(@number_of_players) if @chip_stacks.empty?
      @min_wagers = default_min_wagers(@number_of_rounds) if @min_wagers.empty?
      
      sanity_check_game_definitions
   end
   
   # @see #to_str
   def to_s
      to_str
   end
   
   # @return [String] The game definition in text format.
   def to_str
      list_of_lines = []
      list_of_lines << @betting_type if @betting_type
      list_of_lines << "stack = #{@chip_stacks.join(' ')}" unless @chip_stacks.empty?
      list_of_lines << "numPlayers = #{@number_of_players}" if @number_of_players
      list_of_lines << "blind = #{@blinds.join(' ')}" unless @blinds.empty?
      list_of_lines << "raiseSize = #{@min_wagers.join(' ')}" unless @min_wagers.empty?
      list_of_lines << "numRounds = #{@number_of_rounds}" if @number_of_rounds
      list_of_lines << "firstPlayer = #{@first_player_positions.join(' ')}" unless @first_player_positions.empty?
      list_of_lines << "maxRaises = #{@max_number_of_wagers.join(' ')}" unless @max_number_of_wagers.empty?
      list_of_lines << "numSuits = #{@number_of_suits}" if @number_of_suits
      list_of_lines << "numRanks = #{@number_of_ranks}" if @number_of_ranks
      list_of_lines << "numHoleCards = #{@number_of_hole_cards}" if @number_of_hole_cards
      list_of_lines << "numBoardCards = #{@number_of_board_cards.join(' ')}" unless @number_of_board_cards.empty?
      list_of_lines.join(NEWLINE)
   end
   
   def ==(other_game_definition)
      to_s == other_game_definition.to_s
   end

   private
   
   def initialize_members!      
      @betting_type = BETTING_TYPES[:limit]
      @blinds = []
      @number_of_board_cards = []
      @min_wagers = []
      @first_player_positions = DEFAULT_FIRST_PLAYER_POSITION_IN_EVERY_ROUND
      @max_number_of_wagers = DEFAULT_MAX_NUMBER_Of_WAGERS
      @chip_stacks = []
   end

   def parse_game_definition!(game_definition_file_name)      
      for_every_line_in_file game_definition_file_name do |line|
         break if line.match(/\bend\s*gamedef\b/i)
         next if GameDefinition.game_def_line_not_informative? line
         
         @betting_type = BETTING_TYPES[:limit] if line.match(/\b#{BETTING_TYPES[:limit]}\b/i)
         @betting_type = BETTING_TYPES[:nolimit] if line.match(/\b#{BETTING_TYPES[:nolimit]}\b/i)
         
         @chip_stacks = GameDefinition.check_game_def_line_for_definition line, 'stack', @chip_stacks
         @number_of_players = GameDefinition.check_game_def_line_for_definition line, 'numplayers', @number_of_players         
         @blinds = GameDefinition.check_game_def_line_for_definition line, 'blind', @blinds
         @min_wagers = GameDefinition.check_game_def_line_for_definition line, 'raisesize', @min_wagers
         @number_of_rounds = GameDefinition.check_game_def_line_for_definition line, 'numrounds', @number_of_rounds
         @first_player_positions = GameDefinition.check_game_def_line_for_definition line, 'firstplayer', @first_player_positions
         @max_number_of_wagers = GameDefinition.check_game_def_line_for_definition line, 'maxraises', @max_number_of_wagers
         @number_of_suits = GameDefinition.check_game_def_line_for_definition line, 'numsuits', @number_of_suits
         @number_of_ranks = GameDefinition.check_game_def_line_for_definition line, 'numranks', @number_of_ranks
         @number_of_hole_cards = GameDefinition.check_game_def_line_for_definition line, 'numholecards', @number_of_hole_cards
         @number_of_board_cards = GameDefinition.check_game_def_line_for_definition line, 'numboardcards', @number_of_board_cards
      end      
   end
   
   # @raise GameDefinitionParseError
   def sanity_check_game_definitions     
      error_message = ""
      begin
         # Make sure that everything is defined that needs to be defined
         error_message = "list of player stacks not specified" unless @chip_stacks
         error_message = "list of blinds not specified" unless @blinds
         error_message = "raise size in each round not specified" unless @min_wagers
         error_message = "first player position in each round not specified" unless @first_player_positions
         error_message = "maximum raise in each round not specified" unless @max_number_of_wagers
         error_message = "number of board cards in each round not specified" unless @number_of_board_cards      
         
         # Do all the same checks that the dealer does
         error_message = "Invalid number of rounds: #{@number_of_rounds}" if invalid_number_of_rounds?
         error_message = "Invalid number of players: #{@number_of_players}" if invalid_number_of_players?
         error_message = "Only read #{@chip_stacks.length} stack sizes, need #{@number_of_players}" if not_enough_player_stacks?
         error_message = "only read #{@blinds.length} blinds, need #{@number_of_players}" if not_enough_blinds?
         error_message = "Only read #{@min_wagers} raise sizes, need #{@number_of_rounds}" if not_enough_raise_sizes?

         (0..@number_of_players-1).each do |i|
            if @blinds[i] > @chip_stacks[i]
               error_message = "Blind for player #{i+1} is greater than stack size"
            end
         end

         (0..@number_of_rounds-1).each do |i|
            if invalid_first_player_position? i
               error_message = "invalid first player #{@first_player_positions[i]} on round #{i+1}"
            end
         end

         error_message = "Invalid number of suits: #{@number_of_suits}" if invalid_number_of_suits?
         error_message = "Invalid number of ranks: #{@number_of_ranks}" if invalid_number_of_ranks?
         error_message = "Invalid number of hole cards: #{@number_of_hole_cards}" if invalid_number_of_hole_cards?

         if @number_of_board_cards.length < @number_of_rounds
            error_message = "Only read #{@number_of_board_cards.length} board card numbers, need " +
                    "#{@number_of_rounds}"
         end

         t = @number_of_hole_cards * @number_of_players
         (0..@number_of_rounds-1).each do |i|
            t += @number_of_board_cards[i]
         end

         if t > (@number_of_suits * @number_of_ranks)
            error_message = "Too many hole and board cards for specified deck"
         end
         
      rescue
         error_message = "Undefined instance variable"
      ensure
         raise GameDefinitionParseError, error_message unless error_message.empty?
      end
   end

   def invalid_number_of_rounds?      
      @number_of_rounds.nil? || 0 == @number_of_rounds || @number_of_rounds > MAX_VALUES[:rounds]
   end

   def invalid_number_of_players?      
      @number_of_players < 2 || @number_of_players > MAX_VALUES[:players]
   end

   def invalid_number_of_hole_cards?      
      0 == @number_of_hole_cards || @number_of_hole_cards > MAX_VALUES[:hole_cards]
   end

   def invalid_number_of_ranks?      
      0 == @number_of_ranks || @number_of_ranks > CARD_RANKS.length
   end

   def invalid_number_of_suits?      
      0 == @number_of_suits || @number_of_suits > CARD_SUITS.length
   end

   def invalid_first_player_position?(i)      
      @first_player_positions[i] <= 0 || @first_player_positions[i] > @number_of_players
   end

   def not_enough_raise_sizes?
      @betting_type == 'limit' && @min_wagers.length < @number_of_rounds
   end
   
   def not_enough_player_stacks?
      @chip_stacks.length < @number_of_players
   end
   
   def not_enough_blinds?
      @blinds.length < @number_of_players
   end
   
   def default_min_wagers(number_of_rounds)
      number_of_rounds.times.inject([]) { |list, i| list << @blinds.max }
   end
end
