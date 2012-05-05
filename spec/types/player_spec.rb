
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/player", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/poker_action", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/hand", __FILE__)

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
      
      @patient = Player.join_match @name, @seat, @position_relative_to_user,
         @position_relative_to_dealer, @chip_stack.dup
   end
   
   describe '#join_match' do
      it 'initializes properly' do
         check_data @name,
                    @seat,
                    @position_relative_to_user,
                    @position_relative_to_dealer,
                    @chip_stack,
                    0,
                    Hand.new,
                    [[]],
                    false,
                    false,
                    true,
                    0
      end
   end
   describe '#take_action!' do
      describe 'updates player state properly' do
         it 'given the player checked or called' do
            pending 'changes to PokerAction'
            
            action = mock 'PokerAction'
            action.stubs(:to_acpc_character).returns(PokerAction::LEGAL_ACTIONS[:call])
            @patient.take_action! 
         end
         describe 'given the player bet or raised' do
            it 'in limit' do
               pending
            end
            it 'in no-limit' do
               pending
            end
         end
         it 'given the player folded' do
            pending
         end
      end
   end
   describe '#start_new_hand!' do
      it 'resets player data properly after taking actions' do
         pending
         
         action = mock 'PokerAction'
         @patient.take_action! action
         
         test_patient_after_taking_action action
      end
   end
   describe '#start_new_round!' do
      pending
   end
   
   it 'reports it is not active if it is all-in' do
      @patient.active?.should be == true
      @patient.active?.should be == false
   end
   it 'reports it is not active if it has folded' do
      @patient.active?.should be == true
      @patient.has_folded = true
      @patient.active?.should be == false
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
   
   def check_data(name, seat, position_relative_to_user,
                  position_relative_to_dealer, chip_stack, chip_balance,
                  hole_cards, actions_taken_in_current_hand, has_folded,
                  is_all_in, is_active, round)
      @patient.name.should be == name
      @patient.seat.should be == seat
      @patient.position_relative_to_user.should be == position_relative_to_user
      @patient.position_relative_to_dealer.should be == position_relative_to_dealer
      @patient.chip_stack.should be == chip_stack
      @patient.chip_balance.should be == chip_balance
      @patient.hole_cards.should be == hole_cards
      @patient.actions_taken_in_current_hand.should be == actions_taken_in_current_hand
      @patient.folded?.should be == has_folded
      @patient.all_in?.should be == is_all_in
      @patient.active?.should be == is_active
      @patient.round.should be == round
   end
end