# Spec helper (must include first to track code coverage with SimpleCov)
require_relative 'support/spec_helper'

require 'acpc_dealer'
require 'acpc_poker_types/game_definition'
require 'acpc_poker_types/chip_stack'

include AcpcPokerTypes

describe GameDefinition do
  include AcpcDealer

  describe '::new' do
    it 'creates a new game definition from a hash' do
      x_hash = {
        betting_type: 'limit',
        chip_stacks: [10] * 3,
        number_of_players: 3,
        blinds: [2] * 3,
        raise_sizes: [2] * 3,
        number_of_rounds: 4,
        first_player_positions: [1] * 4,
        max_number_of_wagers: [3] * 4,
        number_of_suits: 4,
        number_of_ranks: 13,
        number_of_hole_cards: 2,
        number_of_board_cards: [2] * 4
      }
      patient = GameDefinition.new(x_hash)
      x_hash[:first_player_positions].map! { |pos| pos - 1 }
      patient.to_h.must_equal(x_hash)
    end
    it 'does not modify the input hash values' do
      x_hash = {
        betting_type: 'limit',
        chip_stacks: [10] * 3,
        number_of_players: 3,
        blinds: [2] * 3,
        raise_sizes: [2] * 3,
        number_of_rounds: 4,
        first_player_positions: [1] * 4,
        max_number_of_wagers: [3] * 4,
        number_of_suits: 4,
        number_of_ranks: 13,
        number_of_hole_cards: 2,
        number_of_board_cards: [2] * 4
      }
      GameDefinition.new(x_hash)
      x_hash[:first_player_positions].must_equal [1]*4
    end
  end

  describe '::default_first_player_positions' do
    it 'works' do
      100.times do |number_of_rounds|
        expected_positions = number_of_rounds.times.inject([]) do |list, j|
          list << 0
        end

        AcpcPokerTypes::GameDefinition.default_first_player_positions(number_of_rounds).must_equal expected_positions
      end
    end
  end
  describe '::default_max_number_of_wagers' do
    it 'works' do
      100.times do |number_of_rounds|
        expected_number_of_wagers = number_of_rounds.times.inject([]) do |list, j|
          list << (2**8 - 1)
        end

        AcpcPokerTypes::GameDefinition.default_max_number_of_wagers(number_of_rounds).must_equal expected_number_of_wagers
      end
    end
  end
  describe '::default_chip_stacks' do
    it 'works' do
      100.times do |number_of_players|
        expected_chip_stacks = number_of_players.times.inject([]) do |list, j|
          list << AcpcPokerTypes::ChipStack.new(2**31 - 1)
        end

        AcpcPokerTypes::GameDefinition.default_chip_stacks(number_of_players).must_equal expected_chip_stacks
      end
    end
  end

  describe '#parse_file and #parse' do
    it "parses all available game definitions properly" do
      AcpcDealer::GAME_DEFINITION_FILE_PATHS.each do |key, groups_of_defs|
        groups_of_defs.each do |key, game_definition_file_name|
          @patient = AcpcPokerTypes::GameDefinition.parse_file game_definition_file_name

          @expected = File.readlines(game_definition_file_name).map do |line|
            line.chomp
          end.reject { |line| line.match(/GAMEDEF/i) }

          check_patient

          @patient = AcpcPokerTypes::GameDefinition.parse @expected

          check_patient
        end
      end
    end
  end

  def check_patient
    Set.new(@patient.to_a).superset?(Set.new(@expected)).must_equal true
  end
end
