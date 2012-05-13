
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/player", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/poker_action", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/hand", __FILE__)

describe Player do
   
   NAME = 'p1'
   SEAT = '1'
   INITIAL_CHIP_STACK = 100000
   BLIND = 100
   
   before(:each) do      
      init_patient
   end
   
   describe '#join_match' do
      it 'initializes properly' do
         check_patient_data INITIAL_CHIP_STACK,
                            0,
                            nil,
                            nil,
                            true,
                            false,
                            false,
                            nil
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
               init_patient
               @position_relative_to_dealer = i
               
               test_sequence_of_non_fold_actions hand
               
               i += 1
            end
         end
         it 'in a continuous game' do
            i = 0
            various_hands do |hand|
               init_patient
               @position_relative_to_dealer = i
               
               test_sequence_of_non_fold_actions hand
               
               i += 1
            end
         end
      end
   end
   describe 'reports it is not active if' do
      it 'it has folded' do   
         action = mock 'PokerAction'
         action.stubs(:to_sym).returns(:fold)
      
         @patient.start_new_hand! BLIND, INITIAL_CHIP_STACK
         @patient.take_action! action
         
         check_patient_data INITIAL_CHIP_STACK - BLIND,
                            -BLIND,
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
         action.stubs(:amount_to_put_in_pot).returns(INITIAL_CHIP_STACK - BLIND)
         
         hand = default_hand
         @patient.start_new_hand! BLIND, INITIAL_CHIP_STACK, hand
         @patient.take_action! action
         
         check_patient_data 0,
                            -INITIAL_CHIP_STACK,
                            hand,
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
   
   def check_patient_data(chip_stack,
                          chip_balance,
                          hole_cards,
                          actions_taken_in_current_hand,
                          has_folded,
                          is_all_in,
                          is_active,
                          round)
      @patient.name.should == NAME
      @patient.seat.should == SEAT
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
   def test_sequence_of_non_fold_actions(hole_cards=default_hand)
      @patient.start_new_hand! BLIND, INITIAL_CHIP_STACK, hole_cards
      
      chip_balance = -BLIND
      chip_stack = INITIAL_CHIP_STACK - BLIND
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
            
            check_patient_data chip_stack,
                               chip_balance,
                               hole_cards,
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
   def init_patient
      @patient = Player.join_match NAME, SEAT, INITIAL_CHIP_STACK
   end
end