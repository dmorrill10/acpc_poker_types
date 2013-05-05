
# Spec helper (must include first to track code coverage with SimpleCov)
require_relative 'support/spec_helper'

require 'acpc_poker_types/poker_action'

describe AcpcPokerTypes::PokerAction do
  DEFAULT_MODIFIER = '9001'
  DEFAULT_COST = 9002

  describe 'legal actions can be retrieved' do
    it 'with ::legal_actions' do
      AcpcPokerTypes::PokerAction.actions.wont_be_empty
    end
  end
  describe '#new' do
    it 'raises an exception if the given action is invalid' do
      ->{AcpcPokerTypes::PokerAction.new('not_an_action')}.must_raise(AcpcPokerTypes::PokerAction::IllegalAction)
    end
    it 'raises an exception if a modifier accompanies an unmodifiable action' do
      unmodifiable_actions = AcpcPokerTypes::PokerAction.actions - AcpcPokerTypes::PokerAction.modifiable_actions
      unmodifiable_actions.each do |a|
        ->{AcpcPokerTypes::PokerAction.new(a, modifier: DEFAULT_MODIFIER)}.must_raise(AcpcPokerTypes::PokerAction::IllegalModification)
      end
    end
    it 'raise an exception if a modifier is given both implicitly and explicitly' do
      ->{AcpcPokerTypes::PokerAction.new('r9001', modifier: DEFAULT_MODIFIER)}.must_raise(AcpcPokerTypes::PokerAction::IllegalModification)
    end
    describe 'creates actions properly' do
      it 'without modifiers' do
        AcpcPokerTypes::PokerAction.actions.each do |a|
          AcpcPokerTypes::PokerAction.new(a)
        end
      end
      it 'with an explicit modifier' do
        AcpcPokerTypes::PokerAction.modifiable_actions.each do |a|
          AcpcPokerTypes::PokerAction.new(a, modifier: DEFAULT_MODIFIER)
        end
      end
      it 'with an implicit modifier' do
        AcpcPokerTypes::PokerAction.modifiable_actions.each do |a|
          AcpcPokerTypes::PokerAction.new(a + DEFAULT_MODIFIER)
        end
      end
      describe 'with explicit cost' do
        it 'when the cost is positive' do
          AcpcPokerTypes::PokerAction.actions.each do |a|
            AcpcPokerTypes::PokerAction.new(a, cost: DEFAULT_COST).cost.must_equal DEFAULT_COST
          end
        end
        it 'when the cost is negative' do
          AcpcPokerTypes::PokerAction.actions.each do |a|
            AcpcPokerTypes::PokerAction.new(a, cost: -DEFAULT_COST).cost.must_equal -DEFAULT_COST
          end
        end
      end
    end
  end
  describe '#to_s' do
    it "prints in the dealer's canonical representation by default" do
      AcpcPokerTypes::PokerAction.actions.each do |a|
        AcpcPokerTypes::PokerAction.new(a).to_s.must_equal (
          case a
          when AcpcPokerTypes::PokerAction::BET
            AcpcPokerTypes::PokerAction::RAISE
          when AcpcPokerTypes::PokerAction::CALL
            AcpcPokerTypes::PokerAction::CALL
          when AcpcPokerTypes::PokerAction::CHECK
            AcpcPokerTypes::PokerAction::CALL
          when AcpcPokerTypes::PokerAction::FOLD
            AcpcPokerTypes::PokerAction::FOLD
          when AcpcPokerTypes::PokerAction::RAISE
            AcpcPokerTypes::PokerAction::RAISE
          end
        )
      end
    end
    it 'works properly when no chips have been added to the pot' do
      AcpcPokerTypes::PokerAction.actions.each do |a|
        AcpcPokerTypes::PokerAction.new(a).to_s(pot_gained_chips: false).must_equal (
          case a
          when AcpcPokerTypes::PokerAction::BET
            AcpcPokerTypes::PokerAction::BET
          when AcpcPokerTypes::PokerAction::CALL
            AcpcPokerTypes::PokerAction::CHECK
          when AcpcPokerTypes::PokerAction::CHECK
            AcpcPokerTypes::PokerAction::CHECK
          when AcpcPokerTypes::PokerAction::FOLD
            AcpcPokerTypes::PokerAction::FOLD
          when AcpcPokerTypes::PokerAction::RAISE
            AcpcPokerTypes::PokerAction::BET
          end
        )
      end
    end
    it 'works properly when the player is not facing a wager' do
      AcpcPokerTypes::PokerAction.actions.each do |a|
        AcpcPokerTypes::PokerAction.new(a).to_s(player_sees_wager: false).must_equal (
          case a
          when AcpcPokerTypes::PokerAction::BET
            AcpcPokerTypes::PokerAction::RAISE
          when AcpcPokerTypes::PokerAction::CALL
            AcpcPokerTypes::PokerAction::CHECK
          when AcpcPokerTypes::PokerAction::CHECK
            AcpcPokerTypes::PokerAction::CHECK
          when AcpcPokerTypes::PokerAction::FOLD
            AcpcPokerTypes::PokerAction::FOLD
          when AcpcPokerTypes::PokerAction::RAISE
            AcpcPokerTypes::PokerAction::RAISE
          end
        )
      end
    end
    it 'works properly when the player is not facing a wager, nor have chips been added to the pot' do
      AcpcPokerTypes::PokerAction.actions.each do |a|
        AcpcPokerTypes::PokerAction.new(a).to_s(player_sees_wager: false, pot_gained_chips: false).must_equal (
          case a
          when AcpcPokerTypes::PokerAction::BET
            AcpcPokerTypes::PokerAction::BET
          when AcpcPokerTypes::PokerAction::CALL
            AcpcPokerTypes::PokerAction::CHECK
          when AcpcPokerTypes::PokerAction::CHECK
            AcpcPokerTypes::PokerAction::CHECK
          when AcpcPokerTypes::PokerAction::FOLD
            AcpcPokerTypes::PokerAction::FOLD
          when AcpcPokerTypes::PokerAction::RAISE
            AcpcPokerTypes::PokerAction::BET
          end
        )
      end
    end
  end
end