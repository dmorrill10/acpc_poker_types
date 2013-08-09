require_relative 'support/spec_helper'

require 'acpc_poker_types/player'

include AcpcPokerTypes

describe Player do
  describe '::new' do
    it 'works' do
      x_seat = 1

      patient = Player.new x_seat

      patient.seat.must_equal x_seat
      patient.balance.must_equal 0
      patient.hand_player.must_be_kind_of NilHandPlayer
      patient.stack.must_equal 0
      patient.contributions.must_equal []
      patient.total_contribution.must_equal 0
      patient.legal_actions.must_equal []
      patient.inactive?.must_equal false
      patient.all_in?.must_equal false
      patient.folded?.must_equal false
      patient.initial_stack.must_equal 0
      patient.ante.must_equal 0
      patient.hand.must_equal Hand.new
      patient.actions.must_equal [[]]
      patient.winnings.must_equal 0
    end
  end
  describe '#hand_player=' do
    it "gives player all of the HandPlayer's methods" do
      x_seat = 1

      patient = Player.new x_seat

      x_hand_player = HandPlayer.new(Hand.from_acpc('AhKs'), 100, 2)
      patient.hand_player = x_hand_player

      patient.seat.must_equal x_seat
      patient.balance.must_equal 0
      patient.hand_player.must_equal x_hand_player
    end
  end
end
