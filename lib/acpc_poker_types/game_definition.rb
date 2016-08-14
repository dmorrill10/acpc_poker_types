require 'acpc_poker_types/suit'
require 'acpc_poker_types/rank'

require 'acpc_poker_types/seat'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# Class that parses and manages game definition information from a game definition file.
module AcpcPokerTypes
  class GameDefinition
    exceptions :parse_error

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

    # @return [Array] The position relative to the dealer that is first to act
    #     in each round, indexed from 0.
    # @example The usual Texas hold'em sequence would look like this:
    #     first_player_positions == [1, 0, 0, 0]
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

    # @return [Integer] The maximum value of an eight bit unsigned integer (for consistency with the ACPC Dealer).
    UINT8_MAX = 2**8 - 1

    DEFAULT_MAX_NUMBER_OF_WAGERS = UINT8_MAX

    # @return [Integer] The maximum value of a 32 bit signed integer (for consistency with the ACPC Dealer).
    INT32_MAX = 2**31 - 1

    DEFAULT_CHIP_STACK = INT32_MAX

    # @return [Hash] Maximum game parameter values.
    MIN_VALUES = {
      :@number_of_rounds => 1,
      :@number_of_players => 2,
      :@number_of_hole_cards => 1,
      :@number_of_suits => 1,
      :@number_of_ranks => 2
    }

    MAX_VALUES = {
      :@number_of_suits => AcpcPokerTypes::Suit::DOMAIN.length,
      :@number_of_ranks => AcpcPokerTypes::Rank::DOMAIN.length
    }

    LIMIT = 'limit'
    NO_LIMIT = 'nolimit'

    # @return [Hash] Betting types understood by this class.
    BETTING_TYPES = {
      :limit => LIMIT,
      :nolimit => NO_LIMIT
    }

    DEFINITIONS = {
      :@chip_stacks => 'stack',
      :@number_of_players => 'numPlayers',
      :@blinds => 'blind',
      :@raise_sizes => 'raiseSize',
      :@number_of_rounds => 'numRounds',
      :@first_player_positions => 'firstPlayer',
      :@max_number_of_wagers => 'maxRaises',
      :@number_of_suits => 'numSuits',
      :@number_of_ranks => 'numRanks',
      :@number_of_hole_cards => 'numHoleCards',
      :@number_of_board_cards => 'numBoardCards'
    }

    ALL_PLAYER_ALL_ROUND_DEFS = [
      DEFINITIONS[:@number_of_players],
      DEFINITIONS[:@number_of_rounds],
      DEFINITIONS[:@number_of_suits],
      DEFINITIONS[:@number_of_ranks],
      DEFINITIONS[:@number_of_hole_cards]
    ]

    def self.default_first_player_positions(number_of_rounds)
      number_of_rounds.times.map { 0 }
    end

    # @return [Array] The default maximum raise in each round.
    def self.default_max_number_of_wagers(number_of_rounds)
      number_of_rounds.times.map { DEFAULT_MAX_NUMBER_OF_WAGERS }
    end

    # @param [Integer] number_of_players The number of players that require stacks.
    # @return [Array<Integer>] The default list of initial stacks for every player.
    def self.default_chip_stacks(number_of_players)
      number_of_players.times.map { DEFAULT_CHIP_STACK }
    end

    # Checks if the given line is a comment beginning with '#' or ';', or empty.
    #
    # @param [String] line
    # @return [Boolean] True if +line+ is a comment or empty, false otherwise.
    def self.line_is_comment_or_empty?(line)
      line.nil? || line.match(/^\s*[#;]/) || line.empty?
    end

    # Checks a given line frcom a game definition file for a game
    # definition name and returns the given default value unless there is a match.
    #
    # @param [String, #match] line A line from a game definition file.
    # @param [String] definition_name The name of the game definition that is
    #     being checked for in +line+.
    # @return The game definition value in +line+ if +line+ contains the game definition
    #     referred to by +definition_name+, +nil+ otherwise.
    def self.check_game_def_line_for_definition(line, definition_name)
      if line.match(/^\s*#{definition_name}\s*=\s*([\d\s]+)/i)
        value = $1.chomp.split(/\s+/).map{ |elem| elem.to_i }
        if ALL_PLAYER_ALL_ROUND_DEFS.include? definition_name
          value.shift
        else
          value
        end
      end
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
    def self.parse_file(game_definition_file_name)
      File.open(game_definition_file_name, 'r') { |file|  parse file }
    end

    class << self; alias_method(:parse, :new); end

    def initialize(definitions)
      @raise_sizes = nil
      @array = nil
      @betting_type = BETTING_TYPES[:limit]
      @number_of_players = MIN_VALUES[:@number_of_players]
      @blinds = @number_of_players.times.inject([]) { |blinds, i| blinds << 0 }
      @number_of_rounds = MIN_VALUES[:@number_of_rounds]
      @number_of_board_cards = @number_of_rounds.times.inject([]) { |cards, i| cards << 0 }
      @first_player_positions = self.class.default_first_player_positions @number_of_rounds
      @max_number_of_wagers = self.class.default_max_number_of_wagers @number_of_rounds
      @chip_stacks = self.class.default_chip_stacks @number_of_players
      @number_of_suits = MIN_VALUES[:@number_of_suits]
      @number_of_ranks = MIN_VALUES[:@number_of_ranks]
      @number_of_hole_cards = MIN_VALUES[:@number_of_hole_cards]

      if definitions.is_a?(Hash)
        assign_definitions! definitions
      else
        parse_definitions! definitions
      end

      @chip_stacks = self.class.default_chip_stacks(@number_of_players) if @chip_stacks.empty?

      unless @first_player_positions.any? { |pos| pos <= 0 }
        @first_player_positions.map! { |position| position - 1 }
      end

      sanity_check_game_definitions!
    end

    def to_s
      to_a.join("\n")
    end

    alias_method :to_str, :to_s

    def to_h
      @hash ||= DEFINITIONS.keys.inject({betting_type: @betting_type}) do |h, instance_variable_symbol|
        h[instance_variable_symbol[1..-1].to_sym] = instance_variable_get(instance_variable_symbol)
        h
      end
    end

    def to_a
      return @array unless @array.nil?

      @array = []
      @array << @betting_type if @betting_type
      @array << "stack = #{@chip_stacks.join(' ')}" unless @chip_stacks.empty?
      @array << "numPlayers = #{@number_of_players}" if @number_of_players
      @array << "blind = #{@blinds.join(' ')}" unless @blinds.empty?
      @array << "raiseSize = #{min_wagers.join(' ')}" unless min_wagers.empty?
      @array << "numRounds = #{@number_of_rounds}" if @number_of_rounds
      @array << "firstPlayer = #{(@first_player_positions.map{|p| p + 1}).join(' ')}" unless @first_player_positions.empty?
      @array << "maxRaises = #{@max_number_of_wagers.join(' ')}" unless @max_number_of_wagers.empty?
      @array << "numSuits = #{@number_of_suits}" if @number_of_suits
      @array << "numRanks = #{@number_of_ranks}" if @number_of_ranks
      @array << "numHoleCards = #{@number_of_hole_cards}" if @number_of_hole_cards
      @array << "numBoardCards = #{@number_of_board_cards.join(' ')}" unless @number_of_board_cards.empty?
      @array
    end

    def ==(other_game_definition)
      to_h == other_game_definition.to_h
    end

    def min_wagers
      @min_wagers ||= if @raise_sizes
        @raise_sizes
      else
        @number_of_rounds.times.map { |i| @blinds.max }
      end
    end

    private

    def set_defintion_if_present!(definition_symbol, line, definition_label_in_line)
      new_definition = self.class.check_game_def_line_for_definition(
        line,
        definition_label_in_line
      )
      if new_definition
        instance_variable_set(definition_symbol, new_definition)
        true
      else
        false
      end
    end

    def assign_definitions!(definitions)
      definitions.each do |key, value|
        instance_variable_set(
          "@#{key}",
          (
            begin
              value.dup
            rescue TypeError
              value
            end
          )
        )
      end
    end

    def parse_definitions!(definitions)
      definitions.each do |line|
        break if line.match(/\bend\s*gamedef\b/i)
        next if (
          self.class.game_def_line_not_informative?(line) ||
          BETTING_TYPES.any? do |type_and_name|
            name = type_and_name[1]
            if line.match(/\b#{name}\b/i)
              @betting_type = name
              true
            else
              false
            end
          end ||
          DEFINITIONS.any? do |symbol, string|
            set_defintion_if_present!(symbol, line, string)
          end
        )
      end

      self
    end

    # @raise ParseError
    def sanity_check_game_definitions!
      adjust_definitions_if_necessary!

      raise ParseError, "list of player stacks not specified" unless @chip_stacks
      raise ParseError, "list of blinds not specified" unless @blinds
      raise ParseError, "raise size in each round not specified" unless min_wagers
      raise ParseError, "first player position in each round not specified" unless @first_player_positions
      raise ParseError, "maximum raise in each round not specified" unless @max_number_of_wagers
      raise ParseError, "number of board cards in each round not specified" unless @number_of_board_cards

      MIN_VALUES.each do |symbol, min_value|
        if instance_variable_get(symbol) < min_value
          raise(
            ParseError,
            "Invalid definition, #{DEFINITION[symbol]} must be greater than #{min_value} but was set to #{instance_variable_get(symbol)}"
          )
        end
      end

      (0..@number_of_players-1).each do |i|
        if @blinds[i] > @chip_stacks[i]
          raise(
            ParseError,
            "Blind for player #{i+1} (#{@blinds[i]}) is greater than stack size (#{@chip_stacks[i]})"
          )
        end
      end

      @number_of_rounds.times do |i|
        unless Seat.in_bounds?(@first_player_positions[i], @number_of_players)
          raise(
            ParseError,
            "Invalid first player #{@first_player_positions[i]} on round #{i+1} for #{@number_of_players} players"
          )
        end
      end

      MAX_VALUES.each do |symbol, max_value|
        if instance_variable_get(symbol) > max_value
          raise(
            ParseError,
            "Invalid definition, #{DEFINITIONS[symbol]} must be less than #{max_value} but was set to #{instance_variable_get(symbol)}"
          )
        end
      end

      number_of_cards_required = (@number_of_hole_cards * @number_of_players) + @number_of_board_cards.inject(:+)

      if number_of_cards_required > (@number_of_suits * @number_of_ranks)
        raise(
          ParseError,
          "Too many hole and board cards (#{number_of_cards_required}) for specified deck (#{(@number_of_suits * @number_of_ranks)})"
        )
      end
    end

    def adjust_definitions_if_necessary!
      if @number_of_players < @chip_stacks.length
        @number_of_players = @chip_stacks.length
      elsif @number_of_players < @blinds.length
        @number_of_players = @blinds.length
      end
      @number_of_players.times do |i|
        @blinds << 0 unless @blinds.length > i
        @chip_stacks << DEFAULT_CHIP_STACK unless @chip_stacks.length > i
      end
      @number_of_rounds.times do |i|
        @first_player_positions << 0 unless @first_player_positions.length > i
        @number_of_board_cards << 0 unless @number_of_board_cards.length > i
        @max_number_of_wagers << DEFAULT_MAX_NUMBER_OF_WAGERS unless @max_number_of_wagers.length > i
      end
    end
  end
end
