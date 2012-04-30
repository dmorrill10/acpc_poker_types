
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/chip_stack", __FILE__)

describe ChipStack do
   describe '#initialization' do
      describe 'raises an exception if the number of chips to be made into a stack' do
         it 'is negative' do
            expect{ChipStack.new(-1)}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
   end
   describe '#to_i and #==' do
      it 'reports the number of chips the stack contains' do
         number_of_chips = 100
         patient = ChipStack.new number_of_chips
         
         patient.to_i.should be number_of_chips
         patient.should ==(number_of_chips)
      end
   end
   describe '#+' do
      describe 'raises an exception if the number of chips to be added to a stack' do
         it 'is more negative than its value' do
            patient = ChipStack.new 100
            expect{patient + -101}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
      it 'adds a number of chips to the stack' do
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         amount_added = 50
         number_of_chips = initial_number_of_chips + amount_added
         
         (patient + amount_added).should ==(number_of_chips)
      end
   end
   describe '#-' do
      describe 'raises an exception if the number of chips to be taken' do
         it 'is greater than the number of chips in the stack' do
            patient = ChipStack.new 100
            expect{patient - 101}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
      it 'takes a number of chips from the stack' do
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         amount_taken = 50
         number_of_chips = initial_number_of_chips - amount_taken
         
         (patient - amount_taken).should ==(number_of_chips)
      end
   end
   describe '#*' do
      describe 'raises an exception if the multiplier' do
         it 'is negative' do
            pending 'A need to multiply ChipStacks'
            patient = ChipStack.new 100
            expect{patient * -101}.to raise_exception(ChipStack::IllegalNumberOfChips)
         end
      end
      it 'multiplies the value of the stack' do
         pending 'A need to multiply ChipStacks'
         initial_number_of_chips = 100
         patient = ChipStack.new initial_number_of_chips
         
         multiplier = 50
         number_of_chips = initial_number_of_chips * multiplier
         
         (patient * multiplier).should ==(number_of_chips)
      end
   end
   describe '#coerce converts Integers to ChipStacks when in' do
      it 'Integer#+' do
         amount_added = 50
         patient = ChipStack.new amount_added
         
         initial_number_of_chips = 100
         number_of_chips = initial_number_of_chips + amount_added
         
         (initial_number_of_chips + patient).should ==(number_of_chips)
      end
      it 'Integer#-' do
         amount_taken = 50
         patient = ChipStack.new amount_taken
         
         initial_number_of_chips = 100
         number_of_chips = initial_number_of_chips - amount_taken
         
         (initial_number_of_chips - patient).should ==(number_of_chips)
      end
      it 'Integer#*' do
         pending 'A need to multiply ChipStacks'
         initial_number_of_chips = 100
         patient = ChipStack.new amount_taken
         
         multiplier = 50
         number_of_chips = multiplier * initial_number_of_chips
         
         (multiplier * patient).should ==(number_of_chips)
      end
   end
end
