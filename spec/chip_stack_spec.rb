
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_poker_types/chip_stack'

describe AcpcPokerTypes::ChipStack do
  describe '#initialization' do
    describe 'raises an exception if the number of chips to be made into a stack' do
      it 'is negative' do
        ->{AcpcPokerTypes::ChipStack.new(-1)}.must_raise(AcpcPokerTypes::ChipStack::IllegalNumberOfChips)
      end
    end
  end
  describe '#to_i and #==' do
    it 'reports the number of chips the stack contains' do
      number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new number_of_chips

      patient.to_i.must_equal number_of_chips
      patient.must_equal(number_of_chips)
    end
  end
  describe '#receive!' do
    it 'raises an exception if the number of chips to be added is greater than the number of chips in the stack' do
      patient = AcpcPokerTypes::ChipStack.new 100
      ->{patient.receive!(-101)}.must_raise(AcpcPokerTypes::ChipStack::IllegalNumberOfChips)
    end
    it 'adds a number of chips to the stack' do
      initial_number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new initial_number_of_chips

      amount_added = 50
      number_of_chips = initial_number_of_chips + amount_added

      patient.receive!(amount_added).must_equal(number_of_chips)
    end
  end
  describe '#give!' do
    it 'raises an exception if the number of chips to be taken is greater than the number of chips in the stack' do
      patient = AcpcPokerTypes::ChipStack.new 100
      ->{patient.give! 101}.must_raise(AcpcPokerTypes::ChipStack::IllegalNumberOfChips)
    end
    it 'takes a number of chips from the stack' do
      initial_number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new initial_number_of_chips

      amount_taken = 50
      number_of_chips = initial_number_of_chips - amount_taken

      patient.give!(amount_taken).must_equal(number_of_chips)
    end
  end
  describe '#+' do
    it 'adds a number of chips to the stack' do
      initial_number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new initial_number_of_chips

      amount_added = 50
      number_of_chips = initial_number_of_chips + amount_added

      (patient + amount_added).must_equal(number_of_chips)
    end
  end
  describe '#-' do
    it 'takes a number of chips from the stack' do
      initial_number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new initial_number_of_chips

      amount_taken = 50
      number_of_chips = initial_number_of_chips - amount_taken

      (patient - amount_taken).must_equal(number_of_chips)
    end
  end
  describe '#*' do
    it 'multiplies the value of the stack' do
      initial_number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new initial_number_of_chips

      multiplier = 50
      number_of_chips = initial_number_of_chips * multiplier

      (patient * multiplier).must_equal(number_of_chips)
    end
  end
  describe '#coerce converts Integers to AcpcPokerTypes::ChipStacks when in' do
    it 'Rational#+' do
      amount_added = 50
      patient = AcpcPokerTypes::ChipStack.new amount_added

      initial_number_of_chips = 100
      number_of_chips = initial_number_of_chips + amount_added

      (initial_number_of_chips + patient).must_equal(number_of_chips)
    end
    it 'Rational#-' do
      amount_taken = 50
      patient = AcpcPokerTypes::ChipStack.new amount_taken

      initial_number_of_chips = 100
      number_of_chips = initial_number_of_chips - amount_taken

      (initial_number_of_chips - patient).must_equal(number_of_chips)
    end
    it 'Rational#*' do
      initial_number_of_chips = 100
      patient = AcpcPokerTypes::ChipStack.new initial_number_of_chips

      multiplier = 50
      number_of_chips = multiplier * initial_number_of_chips

      (multiplier * patient).must_equal(number_of_chips)
    end
  end
end
