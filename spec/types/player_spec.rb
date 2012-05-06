
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/player", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/poker_action", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/hand", __FILE__)

describe Player do
   
   before(:each) do
      @name = 'p1'
      @seat = '1'
      @chip_stack = default_chip_stack
      @hole_cards = default_hand
      
      @patient = Player.join_match @name, @seat, @chip_stack, @hole_cards
   end
   
   describe '#join_match' do
      it 'initializes properly' do
         check_patient_data @name,
                            @seat,
                            @chip_stack,
                            0,
                            @hole_cards,
                            [[]],
                            false,
                            false,
                            true,
                            0
      end
   end
   describe '#take_action!' do
      describe 'updates player state properly' do
         it 'given the player did not fold' do
            test_sequence_of_non_fold_actions
         end
      end
   end
   describe '#start_new_hand!' do
      describe 'resets player data properly after taking actions' do
         it "in Doyle's game" do
            i = 0
            various_hands do |hand|
               @hole_cards = hand
               @position_relative_to_dealer = i
               @chip_stack = default_chip_stack
               
               @patient.start_new_hand! @chip_stack, @hole_cards
               test_sequence_of_non_fold_actions
               
               i += 1
            end
         end
         it 'in a continuous game' do
            i = 0
            various_hands do |hand|
               @hole_cards = hand
               @position_relative_to_dealer = i
               
               @patient.start_new_hand! @chip_stack, @hole_cards
               test_sequence_of_non_fold_actions
               
               i += 1
            end
         end
      end
   end
   describe 'reports it is not active if' do
      it 'it has folded' do   
         action = mock 'PokerAction'
         action.stubs(:to_sym).returns(:fold)
      
         @patient.take_action! action
         check_patient_data @name,
                            @seat,
                            @chip_stack,
                            0,
                            nil,
                           [[action]],
                           true,
                           false,
                           false,
                           0
      end
      it 'it is all-in' do
         action = mock 'PokerAction'
         action.stubs(:to_sym).returns(:raise)
         action.stubs(:amount_to_put_in_pot).returns(@chip_stack.to_i)
         
         @patient.take_action! action
         check_patient_data @name,
                            @seat,
                            0,
                            -@chip_stack.to_i,
                            @hole_cards,
                            [[action]],
                            false,
                            true,
                            false,
                            0
      end
   end
   it 'properly changes its state when it wins chips' do
      @patient.chip_balance.should be == 0
      
      pot_size = 22
      @patient.take_winnings! pot_size
      
      @patient.chip_stack.should be == default_chip_stack + pot_size
      @patient.chip_balance.should be == pot_size
   end
   
   def check_patient_data(name,
                          seat,
                          chip_stack,
                          chip_balance,
                          hole_cards,
                          actions_taken_in_current_hand,
                          has_folded,
                          is_all_in,
                          is_active,
                          round)
      @patient.name.should == name
      @patient.seat.should == seat
      @patient.chip_stack.should == chip_stack
      @patient.chip_balance.should == chip_balance
      @patient.hole_cards.should == hole_cards
      @patient.actions_taken_in_current_hand.should == actions_taken_in_current_hand
      @patient.folded?.should == has_folded
      @patient.all_in?.should == is_all_in
      @patient.active?.should == is_active
      @patient.round.should == round
   end
   def various_actions
      various_amounts_to_put_in_pot do |amount|
         with_and_without_a_modifier do |modifier|
            instantiate_each_action_from_symbols(amount, modifier) do |action|
               yield action
            end
         end
      end
   end
   def default_modifier
      modifier_amount = 9001
      modifier = mock 'ChipStack'
      modifier.stubs(:to_s).returns(modifier_amount.to_s)
      modifier
   end
   def default_chip_stack
      100000
   end
   def various_amounts_to_put_in_pot
      [0, 9002, -9002].each do |amount|
         yield amount
      end
   end
   def with_and_without_a_modifier
      [nil, default_modifier].each do |modifier|
         yield modifier
      end
   end
   def instantiate_each_action_from_symbols(amount_to_put_in_pot=0,
                                            modifier=nil)
      PokerAction::LEGAL_SYMBOLS.each do |sym|
         modifier = if PokerAction::MODIFIABLE_ACTIONS.keys.include? sym
            modifier
         else
            nil
         end
         
         action = mock 'PokerAction'
         action.stubs(:to_sym).returns(sym)
         action.stubs(:to_s).returns(sym.to_s + modifier.to_s)
         action.stubs(:to_acpc).returns(PokerAction::LEGAL_ACTIONS[sym] + modifier.to_s)
         action.stubs(:to_acpc_character).returns(PokerAction::LEGAL_ACTIONS[sym])
         action.stubs(:amount_to_put_in_pot).returns(amount_to_put_in_pot)
         action.stubs(:modifier).returns(modifier)
         
         yield action
      end
   end
   def test_sequence_of_non_fold_actions
      chip_balance = 0
      chip_stack = default_chip_stack
      actions_taken_this_hand = []
         
      number_of_rounds = 4
      number_of_rounds.times do |round|
         @patient.start_new_round! unless 0 == round
            
         actions_taken_this_hand << []
         
         various_actions do |action|
            next if :fold == action.to_sym
            
            chip_balance -= action.amount_to_put_in_pot
            chip_stack -= if chip_stack - action.amount_to_put_in_pot >= 0
               action.amount_to_put_in_pot
            else chip_stack end
            is_all_in = 0 == chip_stack
            is_active = !is_all_in
            
            actions_taken_this_hand.last << action
            
            @patient.take_action! action
            check_patient_data @name,
                               @seat,
                               chip_stack,
                               chip_balance,
                               @hole_cards,
                               actions_taken_this_hand,
                               false,
                               is_all_in,
                               is_active,
                               round
         end
      end
   end
   def various_hands
      ([default_hand] * 10).each do |hole_cards|
         yield hole_cards
      end
   end
   def default_hand
      hidden_cards = mock 'Hand'
      hidden_cards
   end
end