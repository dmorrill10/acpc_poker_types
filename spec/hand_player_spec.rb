
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
  INITIAL_CHIP_STACK = ChipStack.new 100000
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
        x_actions = [
          [
            PokerAction.new('c'),
            PokerAction.new('r200')
          ],
          [
            PokerAction.new('r400'),
            PokerAction.new('c', cost: INITIAL_CHIP_STACK - ANTE)
          ]
        ]
        x_actions.each_with_index do |actions, round|
          actions.each do |action|
            patient.append_action!(action, round)
          end
        end

        -> { patient.append_action!(PokerAction.new(PokerAction::CALL), x_actions.length - 1) }.must_raise HandPlayer::Inactive
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
  describe '#all_in?' do
    it 'works' do
      x_actions = [
        [
          PokerAction.new('c'),
          PokerAction.new('r200')
        ],
        [
          PokerAction.new('r400')
        ]
      ]
      x_actions.each_with_index do |actions, round|
        actions.each do |action|
          patient.append_action!(action, round).all_in?.must_equal false
        end
      end

      patient.append_action!(PokerAction.new('c', cost: INITIAL_CHIP_STACK)).all_in?.must_equal true
    end
  end
  describe '#inactive?' do
    it 'is true if it has gone all in' do
      x_actions = [
        [
          PokerAction.new('c'),
          PokerAction.new('r200')
        ],
        [
          PokerAction.new('r400')
        ]
      ]
      x_actions.each_with_index do |actions, round|
        actions.each do |action|
          patient.append_action!(action, round).inactive?.must_equal false
        end
      end

      patient.append_action!(PokerAction.new('c', cost: INITIAL_CHIP_STACK - ANTE)).inactive?.must_equal true
    end
    it 'is true if it has folded' do
      x_actions = [
        [
          PokerAction.new('c'),
          PokerAction.new('r200')
        ],
        [
          PokerAction.new('r400')
        ]
      ]
      x_actions.each_with_index do |actions, round|
        actions.each do |action|
          patient.append_action!(action, round).inactive?.must_equal false
        end
      end

      patient.append_action!(PokerAction.new(PokerAction::FOLD)).inactive?.must_equal true
    end
  end
  describe '#contributions' do
    it 'works' do
      x_actions = [
        [
          PokerAction.new('c', cost: 100),
          PokerAction.new('r200', cost: 100)
        ],
        [
          PokerAction.new('r400', cost: 200),
          PokerAction.new('c', cost: 0)
        ]
      ]
      x_actions.each_with_index do |actions, round|
        actions.each do |action|
          patient.append_action!(action, round)
        end
      end

      patient.contributions.must_equal x_actions.flatten.inject(0) { |sum, action| sum += action.cost }
    end
  end

  describe '#legal_actions' do
    it 'works with fold' do
      patient.legal_actions(100).all? do |action|
        [
          PokerAction.new(PokerAction::CALL),
          PokerAction.new(PokerAction::RAISE, cost: INITIAL_CHIP_STACK - (ANTE + 100)),
          PokerAction.new(PokerAction::FOLD)
        ].include? action
      end.must_equal true
      patient.append_action!(PokerAction.new('c', cost: 100))
        .legal_actions(200).all? do |action|
          [
            PokerAction.new(PokerAction::CALL),
            PokerAction.new(PokerAction::RAISE, cost: INITIAL_CHIP_STACK - (ANTE + 200)),
            PokerAction.new(PokerAction::FOLD)
          ].include? action
        end.must_equal true
      patient.append_action!(PokerAction.new('f'))
        .legal_actions.empty?.must_equal true
    end
    it 'works with all in' do
      patient.legal_actions.all? do |action|
        [
          PokerAction.new(PokerAction::CHECK),
          PokerAction.new(PokerAction::BET, cost: INITIAL_CHIP_STACK - ANTE),
        ].include? action
      end.must_equal true
      patient.append_action!(PokerAction.new('c', cost: 100))
        .legal_actions.all? do |action|
          [
            PokerAction.new(PokerAction::CHECK),
            PokerAction.new(PokerAction::BET, cost: INITIAL_CHIP_STACK - (ANTE + 100)),
          ].include? action
        end.must_equal true
      patient.append_action!(PokerAction.new('c', cost: INITIAL_CHIP_STACK - (ANTE + 100)))
        .legal_actions.empty?.must_equal true
    end
    it 'works when an opponent is all in' do
      patient.append_action!(PokerAction.new('c', cost: 100))
        .legal_actions.all? do |action|
          [
            PokerAction.new(PokerAction::CHECK),
            PokerAction.new(PokerAction::RAISE, cost: INITIAL_CHIP_STACK - (ANTE + 100))
          ].include? action
        end.must_equal true
      patient.legal_actions(INITIAL_CHIP_STACK - (ANTE + 100)).all? do |action|
        [
          PokerAction.new(PokerAction::CALL),
          PokerAction.new(PokerAction::FOLD)
        ].include? action
      end.must_equal true
    end
  end
end
