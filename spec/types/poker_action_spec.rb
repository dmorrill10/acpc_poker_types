
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../../src/types/poker_action', __FILE__)

describe PokerAction do
   describe 'legal actions can be retrieved' do
      it 'with ::LEGAL_ACTIONS' do
         PokerAction::LEGAL_ACTIONS.should_not be_empty
      end
      
      it 'in symbol format' do
         PokerAction::LEGAL_SYMBOLS.should_not be_empty
      end
      
      it 'in string format' do
         PokerAction::LEGAL_STRINGS.should_not be_empty
      end
      
      it 'in acpc format' do
         PokerAction::LEGAL_ACPC_CHARACTERS.should_not be_empty
      end
   end
   
   describe '#new' do
      it 'raises an exception if the given action is invalid' do
         expect{PokerAction.new(:not_an_action)}.to raise_exception(PokerAction::IllegalPokerAction)
      end
      it 'raises an exception if a modifier accompanies an unmodifiable action' do
         unmodifiable_actions = PokerAction::LEGAL_SYMBOLS - PokerAction::MODIFIABLE_ACTIONS.keys
         modifier_amount = 9001
         modifier = mock 'ChipStack'
         modifier.stubs(:to_s).returns(modifier_amount.to_s)
         unmodifiable_actions.each do |sym|
            expect{PokerAction.new(sym, modifier)}.to raise_exception(PokerAction::IllegalPokerActionModification)
         end
      end
      it 'raise an exception if a modifier is given both implicitly and explicitly' do
         modifier_amount = 9001
         modifier = mock 'ChipStack'
         modifier.stubs(:to_s).returns(modifier_amount.to_s)
         expect{PokerAction.new('r9001', modifier)}.to raise_exception(PokerAction::IllegalPokerActionModification)
      end
      it 'raise an exception if a fold action is given when no wager is seen by the acting player' do
         expect{PokerAction.new('f', nil, false)}.to raise_exception(PokerAction::IllegalPokerAction)
      end
      describe 'treats all defined legal actions as such' do
         it 'when the action is a symbol' do
            instantiate_each_action_from_symbols do |sym, patient|
            end
         end
         it 'when the action is a string' do
            instantiate_each_action_from_strings do |string, patient|
            end
         end
         it 'when the action is an ACPC character' do
            instantiate_each_action_from_acpc_characters do |char, patient|
            end
         end
         it 'when the action is a modified ACPC action' do
            instantiate_each_action_from_modified_acpc_characters do |action, patient|
            end
         end
      end
   end
   
   describe 'without a modifier' do
      before(:each) do
         @modifier = nil
      end
      
      describe 'converts itself into its proper' do
         describe 'symbol' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  patient.to_sym.should be == PokerAction::LEGAL_ACTIONS.key(char)
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  patient.to_sym.should be == string.to_sym
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  patient.to_sym.should be == sym
               end
            end
         end
         describe 'string' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  patient.to_s.should be == PokerAction::LEGAL_ACTIONS.key(char).to_s
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  patient.to_s.should be == string
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  patient.to_s.should be == sym.to_s
               end
            end
         end
         describe 'ACPC character' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  patient.to_acpc_character.should be == char
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  patient.to_acpc_character.should be == PokerAction::LEGAL_ACTIONS[string.to_sym]
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  patient.to_acpc_character.should be == PokerAction::LEGAL_ACTIONS[sym]
               end
            end
         end
         describe 'full ACPC form' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  expected_acpc_form = if PokerAction::MODIFIABLE_ACTIONS.values.include? PokerAction::LEGAL_ACTIONS.key(char)
                     char + @modifier.to_s
                  else
                     char
                  end
                  patient.to_acpc.should be == expected_acpc_form
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  expected_acpc_form = if PokerAction::MODIFIABLE_ACTIONS.keys.include? string.to_sym
                     PokerAction::LEGAL_ACTIONS[string.to_sym] + @modifier.to_s
                  else
                     PokerAction::LEGAL_ACTIONS[string.to_sym]
                  end
                  patient.to_acpc.should be == expected_acpc_form
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  expected_acpc_form = if PokerAction::MODIFIABLE_ACTIONS.keys.include? sym
                     PokerAction::LEGAL_ACTIONS[sym] + @modifier.to_s
                  else
                     PokerAction::LEGAL_ACTIONS[sym]
                  end
                  patient.to_acpc.should be == expected_acpc_form
               end
            end
         end
      end
   end
   
   # @todo Would rather not duplicate this code but I can't find a way to instantiate a mock object outside of an 'it' block, and still the variables from a 'before' block outside 'it' blocks.
   describe 'with a modifier' do
      before(:each) do
         modifier_amount = 9001
         @modifier = mock 'ChipStack'
         @modifier.stubs(:to_s).returns(modifier_amount.to_s)
      end
         
      describe 'converts itself into its proper' do
         describe 'symbol' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  patient.to_sym.should be == PokerAction::LEGAL_ACTIONS.key(char)
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  patient.to_sym.should be == string.to_sym
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  patient.to_sym.should be == sym
               end
            end
         end
         describe 'string' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  patient.to_s.should be == PokerAction::LEGAL_ACTIONS.key(char).to_s
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  patient.to_s.should be == string
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  patient.to_s.should be == sym.to_s
               end
            end
         end
         describe 'ACPC character' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  patient.to_acpc_character.should be == char
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  patient.to_acpc_character.should be == PokerAction::LEGAL_ACTIONS[string.to_sym]
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  patient.to_acpc_character.should be == PokerAction::LEGAL_ACTIONS[sym]
               end
            end
         end
         describe 'full ACPC form' do
            it 'from ACPC form' do
               instantiate_each_action_from_acpc_characters(@modifier) do |char, patient|
                  expected_acpc_form = if PokerAction::MODIFIABLE_ACTIONS.values.include? char
                     char + @modifier.to_s
                  else
                     char
                  end
                  patient.to_acpc.should be == expected_acpc_form
               end
            end
            it 'from string form' do
               instantiate_each_action_from_strings(@modifier) do |string, patient|
                  expected_acpc_form = if PokerAction::MODIFIABLE_ACTIONS.keys.include? string.to_sym
                     PokerAction::LEGAL_ACTIONS[string.to_sym] + @modifier.to_s
                  else
                     PokerAction::LEGAL_ACTIONS[string.to_sym]
                  end
                  patient.to_acpc.should be == expected_acpc_form
               end
            end
            it 'from symbol form' do
               instantiate_each_action_from_symbols(@modifier) do |sym, patient|
                  expected_acpc_form = if PokerAction::MODIFIABLE_ACTIONS.keys.include? sym
                     PokerAction::LEGAL_ACTIONS[sym] + @modifier.to_s
                  else
                     PokerAction::LEGAL_ACTIONS[sym]
                  end
                  patient.to_acpc.should be == expected_acpc_form
               end
            end
         end
      end
      describe 'given knowledge that the acting player does not see a wager' do
         it 'properly changes the given action to its more precise form' do
            PokerAction::HIGH_RESOLUTION_ACTION_CONVERSION.each do |imprecise_action, precise_action|
               next if :fold == imprecise_action
               imprecise_action_character = PokerAction::LEGAL_ACTIONS[imprecise_action]
               precise_action_character = PokerAction::LEGAL_ACTIONS[precise_action]
               if PokerAction::MODIFIABLE_ACTIONS.values.include? imprecise_action_character
                  modifier = @modifier
                  expected_acpc_form = precise_action_character + @modifier.to_s
               else   
                  modifier = nil
                  expected_acpc_form = precise_action_character
               end
               PokerAction.new(imprecise_action_character, modifier, false).to_acpc.should ==(expected_acpc_form)
            end
         end
      end
   end
   
   def instantiate_each_action_from_symbols(given_modifier=nil)
      PokerAction::LEGAL_SYMBOLS.each do |sym|
         modifier = if PokerAction::MODIFIABLE_ACTIONS.keys.include? sym
            given_modifier
         else
            nil
         end
         yield sym, PokerAction.new(sym, modifier)
      end
   end
   def instantiate_each_action_from_strings(given_modifier=nil)
      PokerAction::LEGAL_STRINGS.each do |string|
         modifier = if PokerAction::MODIFIABLE_ACTIONS.keys.include? string.to_sym
            given_modifier
         else
            nil
         end
         yield string, PokerAction.new(string, modifier)
      end
   end
   def instantiate_each_action_from_acpc_characters(given_modifier=nil)
      PokerAction::LEGAL_ACPC_CHARACTERS.each do |char|
         modifier = if PokerAction::MODIFIABLE_ACTIONS.values.include? char
            given_modifier
         else
            nil
         end
         yield char, PokerAction.new(char, modifier)
      end
   end
   def instantiate_each_action_from_modified_acpc_characters(given_modifier=nil)
      unless given_modifier
         given_modifier = mock('ChipStack')
         given_modifier.stubs(:to_s).returns('9001')
      end
      PokerAction::MODIFIABLE_ACTIONS.values.each do |char|
         modified_action = char + given_modifier.to_s
         yield modified_action, PokerAction.new(modified_action)
      end
   end
end
