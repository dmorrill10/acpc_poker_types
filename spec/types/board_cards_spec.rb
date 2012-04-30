
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require "#{LIB_ACPC_POKER_TYPES_PATH}/types/card"
require "#{LIB_ACPC_POKER_TYPES_PATH}/types/board_cards"

describe BoardCards do
   describe '#to_s' do
      it 'prints itself properly' do
         card1 = mock('Card')
         card1.stubs(:to_s).returns('Ah')
         card1.stubs(:to_str).returns('Ah')
         card2 = mock('Card')
         card2.stubs(:to_s).returns('2d')
         card2.stubs(:to_str).returns('2d')
         card3 = mock('Card')
         card3.stubs(:to_s).returns('3c')
         card3.stubs(:to_str).returns('3c')
         card4 = mock('Card')
         card4.stubs(:to_s).returns('4s')
         card4.stubs(:to_str).returns('4s')
         card5 = mock('Card')
         card5.stubs(:to_s).returns('5d')
         card5.stubs(:to_str).returns('5d')
         
         patient = BoardCards.new
         patient.push(card1).push(card2).push(card3).next_round!.push(card4).next_round!.push(card5)
         
         patient.to_s.should be == "/#{card1}#{card2}#{card3}/#{card4}/#{card5}"
      end
   end
end
