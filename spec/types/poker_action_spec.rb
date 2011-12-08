
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# System
require 'set'

# Local classes
require File.expand_path('../../../src/types/poker_action', __FILE__)

describe PokerAction do   
   describe 'legal actions can be retrieved' do
      it 'in symbol format' do
         PokerAction::LEGAL_SYMBOLS.should_not be_empty
      end
      
      it 'in string format' do
         PokerAction::LEGAL_STRINGS.should_not be_empty
      end
      
      it 'in acpc format' do
         PokerAction::LEGAL_ACPC_CHARS.should_not be_empty
      end
   end
   
   describe '#new' do
      it 'raises an exception if the given action is invalid' do
         PokerAction.new(:not_an_action).should raise(PokerAction::NotARecognizedAction)
      end
      #it 'correctly understands all suits currently recognized' do
      #   for_every_suit_in_the_deck { |suit| Suit.new(suit) }
      #end
   end
   #describe '#to_i' do
   #   it 'converts every suit into its proper numeric ACPC representation' do
   #      for_every_suit_in_the_deck do |suit|
   #         patient = Suit.new suit
   #         
   #         string_suit = CARD_SUITS[suit]
   #         integer_suit = CARD_SUIT_NUMBERS[string_suit]
   #         
   #         patient.to_i.should eq(integer_suit)
   #      end
   #   end
   #end
   #describe '#to_s' do
   #   it 'converts every suit into its proper string representation' do
   #      for_every_suit_in_the_deck do |suit|
   #         patient = Suit.new suit
   #         
   #         string_suit = CARD_SUITS[suit]
   #         
   #         patient.to_s.should eq(string_suit)
   #      end
   #   end
   #end   
end
