require 'acpc_poker_types/dealer_data/match_definition'
require 'acpc_poker_types/dealer_data/log_file'

module AcpcPokerTypes::DealerData
  class  HandResults
    attr_reader :data, :final_score, :match_def

    def self.parse_state(state_string)
      if state_string.strip.match(
        /^STATE:\d+:[cfr\d\/]+:[^:]+:([\d\-\.|]+):([\w|]+)$/
        )

        stack_changes = $1.split '|'
        players = $2.split '|'

        players.each_index.inject({}) do |player_results, j|
           player_results[players[j].to_sym] = stack_changes[j].to_f
           player_results
        end
      else
        nil
      end
    end

    def self.parse_score(score_string)
      if score_string.strip.match(
        /^SCORE:([\d\-\.|]+):([\w|]+)$/
        )

        stack_changes = $1.split '|'
        players = $2.split '|'

        players.each_index.inject({}) do |player_results, j|
           player_results[players[j].to_sym] = stack_changes[j].to_f
           player_results
        end
      else
        nil
      end
    end

    def self.parse_file(
      acpc_log_file_path,
      player_names,
      game_def_directory,
      num_hands=nil
    )
       AcpcPokerTypes::DealerData::LogFile.open(acpc_log_file_path, 'r') do |file|
         AcpcPokerTypes::DealerData::HandResults.parse file, player_names, game_def_directory, num_hands
      end
    end

    class << self; alias_method(:parse, :new); end

    def initialize(acpc_log_statements, player_names, game_def_directory, num_hands=nil)
      @final_score = nil
      @match_def = nil

      @data = acpc_log_statements.inject([]) do |accumulating_data, log_line|
        if @match_def.nil?
          @match_def = AcpcPokerTypes::DealerData::MatchDefinition.parse(log_line, player_names, game_def_directory)
        else
          parsed_message = AcpcPokerTypes::DealerData::HandResults.parse_state(log_line)
          if parsed_message
            # Yes, this causes one more result to be parsed than is saved as long as
            # the number of hands is less than the total number in the log, but this
            # keeps behavior consistent between this class and ActionMessages.
            break accumulating_data if accumulating_data.length == num_hands
            accumulating_data << parsed_message
          else
            @final_score = AcpcPokerTypes::DealerData::HandResults.parse_score(log_line) unless @final_score
          end
        end

        accumulating_data
      end
    end
  end
end