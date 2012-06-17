require 'dmorrill10-utils/class'
require 'dmorrill10-utils/enumerable'
require 'dmorrill10-utils/integer'
require 'set'

require File.expand_path('../chip_stack', __FILE__)
require File.expand_path('../suit', __FILE__)
require File.expand_path('../rank', __FILE__)

# Class that parses and manages game definition information from a game definition file.
class GameDefinition
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
    :@number_of_suits => Suit::DOMAIN.length,
    :@number_of_ranks => Rank::DOMAIN.length
  }

  # @return [Hash] Betting types understood by this class.
  BETTING_TYPES = {
    :limit => 'limit',
    :nolimit => 'nolimit'
  }

  DEFINITIONS = {
    :@chip_stacks => 'stack',
    :@number_of_players => 'numPlayers',
    :@blinds => 'blind',
    :@min_wagers => 'raiseSize',
    :@number_of_rounds => 'numRounds',
    :@first_player_positions => 'firstPlayer',
    :@max_number_of_wagers => 'maxRaises',
    :@number_of_suits => 'numSuits',
    :@number_of_ranks => 'numRanks',
    :@number_of_hole_cards => 'numHoleCards',
    :@number_of_board_cards => 'numBoardCards'
  }

  def self.default_first_player_positions(number_of_rounds)
    number_of_rounds.to_i.times.inject([]) do |list, i|
      list << 0
    end
  end

  # @return [Array] The default maximum raise in each round.
  def self.default_max_number_of_wagers(number_of_rounds)
    number_of_rounds.to_i.times.inject([]) do |list, i|
      list << DEFAULT_MAX_NUMBER_OF_WAGERS
    end
  end

  # @param [Integer] number_of_players The number of players that require stacks.
  # @return [Array<ChipStack>] The default list of initial stacks for every player.
  def self.default_chip_stacks(number_of_players)
    number_of_players.to_i.times.inject([]) do |list, i|
      list << ChipStack.new(DEFAULT_CHIP_STACK)
    end
  end

  # @param [Array] array The array to flatten into a single element.
  # @return +array+ if +array+ has more than one element, the single element in +array+ otherwise.
  def self.flatten_if_single_element_array(array)
    if 1 == array.length then array[0] else array end
  end

  # Checks if the given line is a comment beginning with '#' or ';', or empty.
  #
  # @param [String] line
  # @return [Boolean] True if +line+ is a comment or empty, false otherwise.
  def self.line_is_comment_or_empty?(line)
    line.nil? || line.match(/^\s*[#;]/) || line.empty?
  end

  # Checks a given line from a game definition file for a game
  # definition name and returns the given default value unless there is a match.
  #
  # @param [String, #match] line A line from a game definition file.
  # @param [String] definition_name The name of the game definition that is
  #     being checked for in +line+.
  # @return The game definition value in +line+ if +line+ contains the game definition
  #     referred to by +definition_name+, +nil+ otherwise.
  def self.check_game_def_line_for_definition(line, definition_name)
    if line.match(/^\s*#{definition_name}\s*=\s*([\d\s]+)/i)
      values = $1.chomp.split(/\s+/)
      (0..values.length-1).each do |i|
        values[i] = values[i].to_i
      end
      GameDefinition.flatten_if_single_element_array values
    end
  end

  # Checks if the given line from a game definition file is informative or not
  # (in which case the line is either: a comment beginning with '#', empty, or
  # contains 'gamedef').
  #
  # @return [String] line The line to check.
  # @return [Boolean] +true+ if the line is not informative, +false+ otherwise.
  def self.game_def_line_not_informative?(line)
    GameDefinition.line_is_comment_or_empty?(line) || line.match(/\s*gamedef\s*/i)
  end

  # @param [String] game_definition_file_name The name of the game definition file that this instance should parse.
  # @raise (see #initialize)
  def self.parse_file(game_definition_file_name)
    File.open(game_definition_file_name, 'r') { |file|  GameDefinition.parse file }
  end

  alias_new :parse

  # @raise GameDefinitionParseError
  def initialize(definitions)
    initialize_members!
    begin
      parse_definitions! definitions
    rescue => unable_to_read_or_open_file_error
      raise GameDefinitionParseError, unable_to_read_or_open_file_error.message
    end

    @chip_stacks = GameDefinition.default_chip_stacks(@number_of_players) if @chip_stacks.empty?
    @min_wagers = default_min_wagers(@number_of_rounds) if @min_wagers.empty?

    unless @first_player_positions.any? { |pos| pos <= 0 }
      @first_player_positions.map! { |position| position - 1 }
    end

    sanity_check_game_definitions!
  end

  def to_s
    to_a.join("\n")
  end

  alias_method :to_str, :to_s

  def to_a
    list_of_lines = []
    list_of_lines << BETTING_TYPES[@betting_type] if @betting_type
    list_of_lines << "stack = #{@chip_stacks.join(' ')}" unless @chip_stacks.empty?
    list_of_lines << "numPlayers = #{@number_of_players}" if @number_of_players
    list_of_lines << "blind = #{@blinds.join(' ')}" unless @blinds.empty?
    list_of_lines << "raiseSize = #{@min_wagers.join(' ')}" unless @min_wagers.empty?
    list_of_lines << "numRounds = #{@number_of_rounds}" if @number_of_rounds
    list_of_lines << "firstPlayer = #{(@first_player_positions.map{|p| p + 1}).join(' ')}" unless @first_player_positions.empty?
    list_of_lines << "maxRaises = #{@max_number_of_wagers.join(' ')}" unless @max_number_of_wagers.empty?
    list_of_lines << "numSuits = #{@number_of_suits}" if @number_of_suits
    list_of_lines << "numRanks = #{@number_of_ranks}" if @number_of_ranks
    list_of_lines << "numHoleCards = #{@number_of_hole_cards}" if @number_of_hole_cards
    list_of_lines << "numBoardCards = #{@number_of_board_cards.join(' ')}" unless @number_of_board_cards.empty?
    list_of_lines
  end

  def ==(other_game_definition)
    Set.new(to_a) == Set.new(other_game_definition.to_a)
  end

  private

  def initialize_members!
    @betting_type = BETTING_TYPES[:limit]
    @number_of_players = MIN_VALUES[:@number_of_players]
    @blinds = @number_of_players.times.inject([]) { |blinds, i| blinds << 0 }
    @number_of_rounds = MIN_VALUES[:@number_of_rounds]
    @number_of_board_cards = @number_of_rounds.times.inject([]) { |cards, i| cards << 0 }
    @min_wagers = @number_of_rounds.times.inject([]) { |wagers, i| wagers << @blinds.max }
    @first_player_positions = GameDefinition.default_first_player_positions @number_of_rounds
    @max_number_of_wagers = GameDefinition.default_max_number_of_wagers @number_of_rounds
    @chip_stacks = GameDefinition.default_chip_stacks @number_of_players
    @number_of_suits = MIN_VALUES[:@number_of_suits]
    @number_of_ranks = MIN_VALUES[:@number_of_ranks]
    @number_of_hole_cards = MIN_VALUES[:@number_of_hole_cards]

    self
  end

  def set_defintion_if_present!(definition_symbol, line, definition_label_in_line)
    new_definition = GameDefinition.check_game_def_line_for_definition line, definition_label_in_line
    if new_definition
      instance_variable_set(definition_symbol, new_definition)
      true
    else
      false
    end
  end

  def parse_definitions!(definitions)
    definitions.each do |line|
      break if line.match(/\bend\s*gamedef\b/i)

      next if (
        GameDefinition.game_def_line_not_informative?(line) ||
        BETTING_TYPES.any? do |type_and_name|
          type = type_and_name.first
          name = type_and_name[1]
          if line.match(/\b#{name}\b/i)
            @betting_type = type
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

  # @raise GameDefinitionParseError
  def sanity_check_game_definitions!
    adjust_definitions_if_necessary!

    raise GameDefinitionParseError, "list of player stacks not specified" unless @chip_stacks
    raise GameDefinitionParseError, "list of blinds not specified" unless @blinds
    raise GameDefinitionParseError, "raise size in each round not specified" unless @min_wagers
    raise GameDefinitionParseError, "first player position in each round not specified" unless @first_player_positions
    raise GameDefinitionParseError, "maximum raise in each round not specified" unless @max_number_of_wagers
    raise GameDefinitionParseError, "number of board cards in each round not specified" unless @number_of_board_cards

    MIN_VALUES.each do |symbol, min_value|
      if instance_variable_get(symbol) < min_value
        raise(
          GameDefinitionParseError,
          "Invalid definition, #{DEFINITION[symbol]} must be greater than #{min_value} but was set to #{instance_variable_get(symbol)}"
        )
      end
    end

    (0..@number_of_players-1).each do |i|
      if @blinds[i] > @chip_stacks[i]
        raise(
          GameDefinitionParseError,
          "Blind for player #{i+1} (#{@blinds[i]}) is greater than stack size (#{@chip_stacks[i]})"
        )
      end
    end

    @number_of_rounds.times do |i|
      unless @first_player_positions[i].seat_in_bounds? @number_of_players
        raise(
          GameDefinitionParseError,
          "Invalid first player #{@first_player_positions[i]} on round #{i+1}"
        )
      end
    end

    MAX_VALUES.each do |symbol, max_value|
      if instance_variable_get(symbol) > max_value
        raise(
          GameDefinitionParseError,
          "Invalid definition, #{DEFINITIONS[symbol]} must be less than #{max_value} but was set to #{instance_variable_get(symbol)}"
        )
      end
    end

    number_of_cards_required = (@number_of_hole_cards * @number_of_players) + @number_of_board_cards.sum

    if number_of_cards_required > (@number_of_suits * @number_of_ranks)
      raise(
        GameDefinitionParseError,
        "Too many hole and board cards (#{number_of_cards_required}) for specified deck (#{(@number_of_suits * @number_of_ranks)})"
      )
    end
  end

  def adjust_definitions_if_necessary!
    @number_of_players.times do |i|
      @blinds << 0 unless @blinds.length > i
      @chip_stacks << DEFAULT_CHIP_STACK unless @chip_stacks.length > i
    end
    @number_of_rounds.times do |i|
      @first_player_positions << 0 unless @first_player_positions.length > i
      @number_of_board_cards << 0 unless @number_of_board_cards.length > i

      @min_wagers << @blinds.max unless @min_wagers.length > i
    end
  end
end
