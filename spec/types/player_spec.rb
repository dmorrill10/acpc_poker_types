
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/player", __FILE__)

describe Player do
   class FakeChipStack
      include Comparable
      
      def initialize(number)
         @value = number.to_i
      end
      def <=>(other)
         if @value < other.to_i
            -1
         elsif @value > other.to_i
            1
         else
            0
         end
      end
      def coerce(other)
         [FakeChipStack.new(other.to_i), self]
      end
      def to_i
         @value
      end
      def +(number)
         @value + number.to_i
      end
      def -(number)
         @value - number.to_i
      end
   end
   
   before(:each) do
      @name = 'p1'
      @seat = '1'
      @position_relative_to_dealer = '0'
      @position_relative_to_user = '1'
      @chip_stack = FakeChipStack.new 2000
      
      @patient = Player.new @name, @seat, @position_relative_to_dealer, @position_relative_to_user, @chip_stack.dup
   end
   
   it 'reports its attributes correctly' do
      @patient.name.should be == @name
      @patient.seat.should be == @seat
      @patient.position_relative_to_dealer.should be == @position_relative_to_dealer
      @patient.position_relative_to_user.should be == @position_relative_to_user
      @patient.chip_stack.should be == @chip_stack
   end
   it 'reports it is not active if it is all-in' do
      @patient.is_active?.should be == true
      @patient.is_all_in = true
      @patient.is_active?.should be == false
   end
   it 'reports it is not active if it has folded' do
      @patient.is_active?.should be == true
      @patient.has_folded = true
      @patient.is_active?.should be == false
   end
   it 'properly changes its state when it contributes chips to a side-pot' do
      @patient.chip_balance.should be == 0
      @patient.chip_stack.should be == @chip_stack
      
      @patient.take_from_chip_stack! @chip_stack
      
      @patient.chip_stack.should be == 0
      @patient.chip_balance.should be == -@chip_stack.to_i
   end
   it 'properly changes its state when it wins chips' do
      @patient.chip_balance.should be == 0
      
      pot_size = 22
      @patient.take_winnings! pot_size
      
      @patient.chip_stack.should be == @chip_stack + pot_size
      @patient.chip_balance.should be == pot_size
   end
end