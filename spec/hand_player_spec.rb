
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
  HAND = Hand.from_acpc('AhKs')
  
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
end