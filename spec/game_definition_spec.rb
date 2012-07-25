
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_dealer'

require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/game_definition", __FILE__)

require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/../acpc_poker_types", __FILE__)

describe GameDefinition do
  include AcpcDealer

  describe '::default_first_player_positions' do
    it 'works' do
      100.times do |number_of_rounds|
        expected_positions = number_of_rounds.times.inject([]) do |list, j|
          list << 0
        end

        GameDefinition.default_first_player_positions(number_of_rounds).should == expected_positions
      end
    end
  end
  describe '::default_max_number_of_wagers' do
    it 'works' do
      100.times do |number_of_rounds|
        expected_number_of_wagers = number_of_rounds.times.inject([]) do |list, j|
          list << (2**8 - 1)
        end

        GameDefinition.default_max_number_of_wagers(number_of_rounds).should == expected_number_of_wagers
      end
    end
  end
  describe '::default_chip_stacks' do
    it 'works' do
      100.times do |number_of_players|
        expected_chip_stacks = number_of_players.times.inject([]) do |list, j|
          list << ChipStack.new(2**31 - 1)
        end

        GameDefinition.default_chip_stacks(number_of_players).should == expected_chip_stacks
      end
    end
  end

  describe '#parse_file and #parse' do
    it "parses all available game definitions properly" do
      AcpcDealer::GAME_DEFINITION_FILE_PATHS.each do |key, groups_of_defs|
        groups_of_defs.each do |key, game_definition_file_name|
          @patient = GameDefinition.parse_file game_definition_file_name

          @expected = File.readlines(game_definition_file_name).map do |line|
            line.chomp
          end.reject { |line| line.match(/GAMEDEF/i) }

          check_patient

          @patient = GameDefinition.parse @expected

          check_patient
        end
      end
    end
  end

  def check_patient
    Set.new(@patient.to_a).superset?(Set.new(@expected)).should be true
  end
end
