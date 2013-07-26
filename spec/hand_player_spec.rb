
# Spec helper (must include first to track code coverage with SimpleCov)
require_relative 'support/spec_helper'

require 'acpc_dealer'
require 'acpc_poker_types/acpc_dealer_data/poker_match_data'

require 'acpc_poker_types/hand_player'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/match_state'

include AcpcPokerTypes

describe HandPlayer do
  INITIAL_CHIP_STACK = 100000
  ANTE = 100
  HAND = Hand.from_acpc('AhKs')

  def patient
    @patient ||= HandPlayer.new HAND, INITIAL_CHIP_STACK, ANTE
  end

  describe '::new' do
    it 'raises an exception if the player is unable to pay the ante' do
      -> { HandPlayer.new HAND, INITIAL_CHIP_STACK, INITIAL_CHIP_STACK + 1 }.must_raise HandPlayer::UnableToPayAnte
    end
    it 'works' do
      [0, 100].each do |ante|
        @patient = HandPlayer.new HAND, INITIAL_CHIP_STACK, ante

        @patient.hand.must_equal HAND
        @patient.stack.must_equal INITIAL_CHIP_STACK - ante
        @patient.ante.must_equal ante
        @patient.initial_stack.must_equal INITIAL_CHIP_STACK
      end
    end
  end
  describe '#append_action!' do
    describe 'raises an exception if it is not active' do
      it 'if it has folded' do
        x_actions = [['c', 'r100'], ['r200', 'c'], ['f']]
        x_actions.each_with_index do |actions, round|
          actions.each do |action|
            patient.append_action! PokerAction.new(action), round
          end
        end

        -> { patient.append_action!(PokerAction.new(PokerAction::CALL), x_actions.length - 1) }.must_raise HandPlayer::Inactive
      end
      it 'if it has gone all in' do
        skip
      end
    end
    it 'works' do
      x_actions = [['c', 'r100'], ['r200', 'c'], ['f']]
      x_actions.each_with_index do |actions, round|
        actions.each do |action|
          patient.append_action! PokerAction.new(action), round
        end
      end

      patient.actions.must_equal x_actions
    end
  end
  describe '#folded?' do
    it 'works' do
      x_actions = [['c', 'r100'], ['r200', 'c']]
      x_actions.each_with_index do |actions, round|
        actions.each do |action|
          patient.append_action!(PokerAction.new(action), round).folded?.must_equal false
        end
      end

      patient.append_action!(PokerAction.new(PokerAction::FOLD), x_actions.length - 1).folded?.must_equal true
    end
  end
end