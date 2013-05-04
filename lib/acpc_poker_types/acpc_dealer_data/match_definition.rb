
require 'set'

require 'acpc_poker_types/game_definition'

require 'dmorrill10-utils/class'

module AcpcPokerTypes::AcpcDealerData
  class MatchDefinition

    exceptions :unable_to_parse, :incorrect_number_of_player_names

    attr_reader :name, :game_def, :number_of_hands, :random_seed, :player_names

    def self.parse(acpc_log_string, player_names, game_def_directory)
      if acpc_log_string.strip.match(
        '^\s*#\s*name/game/hands/seed\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s*$'
      )
        name = $1
        game_def = AcpcPokerTypes::GameDefinition.parse_file(
          File.join(game_def_directory, File.basename($2))
        )
        number_of_hands = $3
        random_seed = $4

        new(name, game_def, number_of_hands, random_seed, player_names)
      else
        nil
      end
    end

    def initialize(name, game_def, number_of_hands, random_seed, player_names)
      if game_def.number_of_players != player_names.length
        raise IncorrectNumberOfPlayerNames, "number of players: #{game_def.number_of_players}, number of names: #{player_names.length}"
      end

      @name = name.to_s
      @game_def = game_def
      @number_of_hands = number_of_hands.to_i
      @random_seed = random_seed.to_i
      @player_names = player_names
    end

    def ==(other)
      (
        @name == other.name &&
        Set.new(@game_def.to_a) == Set.new(other.game_def.to_a) &&
        @number_of_hands == other.number_of_hands &&
        @random_seed == other.random_seed &&
        @player_names == other.player_names
      )
    end
  end
end