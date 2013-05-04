
# Spec helper (must include first to track code coverage with SimpleCov)
require_relative 'support/spec_helper'

require 'acpc_poker_types/game_definition'
require 'acpc_dealer'

require 'acpc_poker_types/acpc_dealer_data/match_definition'

describe AcpcPokerTypes::AcpcDealerData::MatchDefinition do
  before do
    @name = nil
    @game_def = nil
    @number_of_hands = nil
    @random_seed = nil
    @player_names = nil
    @patient = nil
  end

  it 'raises an exception if the number of player names does not match the number of players' do
    init_components do
      ->() do
        @patient = AcpcPokerTypes::AcpcDealerData::MatchDefinition.new(
          @name,
          @game_def,
          @number_of_hands,
          @random_seed,
          @player_names + ['extra player']
        )
      end.must_raise AcpcPokerTypes::AcpcDealerData::MatchDefinition::IncorrectNumberOfPlayerNames

      ->() do
        @patient = AcpcPokerTypes::AcpcDealerData::MatchDefinition.new(
          @name,
          @game_def,
          @number_of_hands,
          @random_seed,
          [@player_names.first]
        )
      end.must_raise AcpcPokerTypes::AcpcDealerData::MatchDefinition::IncorrectNumberOfPlayerNames
    end
  end

  describe 'can be created by providing components' do
    it 'separately' do
      init_components do
        @patient = AcpcPokerTypes::AcpcDealerData::MatchDefinition.new(
          @name,
          @game_def,
          @number_of_hands,
          @random_seed,
          @player_names
        )

        check_patient
      end
    end
    it 'in string format "# name/game/hands/seed ..."' do
      init_components do
        string = "# name/game/hands/seed #{@name} #{@game_def_file_name} #{@number_of_hands} #{@random_seed}\n"
        @patient = AcpcPokerTypes::AcpcDealerData::MatchDefinition.parse(string, @player_names, File.dirname(@game_def_file_name))

        check_patient
      end
    end
  end
  it 'returns nil if asked to parse an improperly formatted string' do
    string = 'improperly formatted string'
    @patient = AcpcPokerTypes::AcpcDealerData::MatchDefinition.parse(string, ['p1', 'p2'], 'game def directory').must_be_nil
  end

  def init_components
    @name = 'match_name'
    AcpcDealer::GAME_DEFINITION_FILE_PATHS.each do |number_of_players, game_def_hash|
      game_def_hash.each do |betting_type, file_name|
        @game_def_file_name = file_name
        @game_def = AcpcPokerTypes::GameDefinition.parse_file(@game_def_file_name)
        @number_of_hands = 100
        @random_seed = 9001
        @player_names = number_of_players.times.inject([]) do |names, i|
          names << "p#{i}"
        end

        yield
      end
    end
  end
  def check_patient
    @patient.name.must_equal @name
    Set.new(@patient.game_def.to_a).must_equal Set.new(@game_def.to_a)
    @patient.number_of_hands.must_equal @number_of_hands
    @patient.random_seed.must_equal @random_seed
    @patient.player_names.must_equal @player_names
  end
end
