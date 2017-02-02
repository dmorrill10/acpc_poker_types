
require_relative 'support/spec_helper'

require 'acpc_dealer'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/card'
require 'acpc_poker_types/players_at_the_table'
require 'acpc_poker_types/dealer_data'

include AcpcPokerTypes

describe PlayersAtTheTable do
  describe '#update!' do
    it "keeps track of state for a sequence of match states and actions in Doyle's game" do
      # Change this number to do more or less thorough tests.
      # They are expensive, so don't make this number too large
      num_hands = 5
      MatchLog.all.each do |log_description|
        @match = DealerData::PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          num_hands
        )
        @match.for_every_seat! do |users_seat|

          @patient = PlayersAtTheTable.seat_players(@match.match_def.game_def, users_seat)

          check_patient

          @match.for_every_hand! do
            @match.for_every_turn! do
              @patient.update! @match.current_hand.current_match_state
              check_patient
            end
          end
        end
      end
    end
  end
  describe '#match_ended?' do
    let(:game_def) do
      GameDefinition.new(
        :betting_type=>"nolimit",
        :chip_stacks=>[20000, 20000],
        :number_of_players=>2,
        :blinds=>[100, 50],
        :raise_sizes=>nil,
        :number_of_rounds=>4,
        :first_player_positions=>[1, 0, 0, 0],
        :number_of_suits=>4,
        :number_of_ranks=>13,
        :number_of_hole_cards=>2,
        :number_of_board_cards=>[0, 3, 1, 1]
      )
    end
    it 'works' do
      match_state = MatchState.parse(
        "MATCHSTATE:1:1:39950|50:c///:9cJc|7s5d/Tc4h6d/7d/Qh"
      )
      patient = PlayersAtTheTable.seat_players(game_def, 0)
      patient.update! match_state
      patient.match_ended?.must_equal false
    end
  end

  def check_patient(patient=@patient)
    patient.player_acting_sequence.must_equal @match.player_acting_sequence
    patient.players.length.must_equal @match.players.length
    check_next_to_act
    check_last_turn
    patient.player_acting_sequence_string.must_equal @match.player_acting_sequence_string
    patient.users_turn_to_act?.must_equal @match.users_turn_to_act?
    check_betting_sequence(patient)

    if @match.current_hand
      patient.hand_ended?.must_equal @match.current_hand.final_turn?
      unless @match.current_hand.final_turn?
        patient.match_state.all_hands.each do |hand|
          hand.each do |card|
            card.must_be_kind_of AcpcPokerTypes::Card
          end
        end
      end
    end
    # @todo Test this eventually
    # patient.min_wager.to_i.must_equal @min_wager.to_i
  end

  def check_player_blind_relation(patient)
    patient.position_relative_to_dealer(patient.big_blind_payer).must_equal(
      @match.match_def.game_def.blinds.index(@match.match_def.game_def.blinds.max)
    )
    patient.position_relative_to_dealer(patient.small_blind_payer).must_equal(
      @match.match_def.game_def.blinds.index do |blind|
        blind < @match.match_def.game_def.blinds.max && blind > 0
      end
    )
  end
  def check_betting_sequence(patient)
    x_betting_sequence = @match.betting_sequence.map do |actions|
      actions.map { |action| AcpcPokerTypes::PokerAction.new(action).to_s }
    end

    return x_betting_sequence.flatten.empty?.must_equal(true) unless patient.match_state

    patient.match_state.betting_sequence.map do |actions|
      actions.map { |action| AcpcPokerTypes::PokerAction.new(action).to_s }
    end.must_equal x_betting_sequence

    patient.match_state.betting_sequence_string.scan(/([a-z]\d*|\/)/).flatten.map do |action|
      if action.match(/\//)
        action
      else
        AcpcPokerTypes::PokerAction.new(action).to_s
      end
    end.join('').must_equal @match.betting_sequence_string
  end
  def check_next_to_act(patient=@patient)
    if @match.current_hand && @match.current_hand.next_action
      patient.next_player_to_act.seat.must_equal @match.current_hand.next_action.seat
    else
      patient.next_player_to_act.seat.must_be_nil
    end
  end
  def check_last_turn(patient=@patient)
    return unless @match.current_hand && @match.current_hand.final_turn?

    patient.players.players_close_enough?(@match.players).must_equal true
    check_player_blind_relation(patient)
  end
end

class Array
  def players_close_enough?(other_players)
    return false if other_players.length != length
    each_with_index do |player, index|
      return false unless player.close_enough?(other_players[index])
    end
    true
  end
  def reject_empty_elements
    reject do |elem|
      elem.empty?
    end
  end
end

class Player
  def close_enough?(other)
    @seat == other.seat &&
    balance == other.balance
  end
end
