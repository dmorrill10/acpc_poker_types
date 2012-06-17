
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/poker_action", __FILE__)

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
      unmodifiable_actions.each do |sym|
        expect{PokerAction.new(sym, {modifier: default_modifier})}.to raise_exception(PokerAction::IllegalPokerActionModification)
      end
    end
    it 'raise an exception if a modifier is given both implicitly and explicitly' do
      expect{PokerAction.new('r9001', {modifier: default_modifier})}.to raise_exception(PokerAction::IllegalPokerActionModification)
    end
    it 'raise an exception if a fold action is given when no wager is seen by the acting player' do
      expect{PokerAction.new('f', {acting_player_sees_wager: false})}.to raise_exception(PokerAction::IllegalPokerAction)
    end
    describe 'creates actions properly' do
      it 'from various forms' do
        various_amounts_to_put_in_pot do |amount|
          with_and_without_a_modifier do |modifier|
            instantiate_each_action_from_acpc_characters(amount, modifier) do |char, actual_modifier|
              check_patient_data PokerAction::LEGAL_ACTIONS.key(char),
                PokerAction::LEGAL_ACTIONS.key(char).to_s + actual_modifier.to_s,
                char + actual_modifier.to_s,
                char,
                amount,
                actual_modifier
            end
            instantiate_each_action_from_strings(amount, modifier) do |string, actual_modifier|
              check_patient_data string.to_sym,
                string + actual_modifier.to_s,
                PokerAction::LEGAL_ACTIONS[string.to_sym] + actual_modifier.to_s,
                PokerAction::LEGAL_ACTIONS[string.to_sym],
                amount,
                actual_modifier
            end
            instantiate_each_action_from_symbols(amount, modifier) do |sym, actual_modifier|
              check_patient_data sym,
                sym.to_s + actual_modifier.to_s,
                PokerAction::LEGAL_ACTIONS[sym] + actual_modifier.to_s,
                PokerAction::LEGAL_ACTIONS[sym],
                amount,
                actual_modifier
            end
            instantiate_each_action_from_modified_acpc_characters(amount, modifier) do |char, actual_modifier|
              check_patient_data PokerAction::LEGAL_ACTIONS.key(char),
                PokerAction::LEGAL_ACTIONS.key(char).to_s + actual_modifier.to_s,
                char + actual_modifier.to_s,
                char,
                amount,
                actual_modifier
            end
            instantiate_each_action_from_modified_strings(amount, modifier) do |string, actual_modifier|
              check_patient_data string.to_sym,
                string + actual_modifier.to_s,
                PokerAction::LEGAL_ACTIONS[string.to_sym] + actual_modifier.to_s,
                PokerAction::LEGAL_ACTIONS[string.to_sym],
                amount,
                actual_modifier
            end
          end
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
          modifier = default_modifier
          expected_acpc_form = precise_action_character + modifier.to_s
        else
          modifier = nil
          expected_acpc_form = precise_action_character
        end
        PokerAction.new(imprecise_action_character, {modifier: modifier, acting_player_sees_wager: false}).to_acpc.should ==(expected_acpc_form)
      end
    end
  end

  def default_modifier
    modifier_amount = 9001
    modifier = mock 'ChipStack'
    modifier.stubs(:to_s).returns(modifier_amount.to_s)
    modifier
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
  def check_patient_data(expected_sym,
                         expected_string,
                         expected_acpc,
                         expected_acpc_character,
                         amount_to_put_in_pot=0,
                         modifier=nil)
    @patient.to_sym.should be == expected_sym
    @patient.to_s.should be == expected_string
    @patient.to_acpc.should be == expected_acpc
    @patient.to_acpc_character.should be == expected_acpc_character
    @patient.amount_to_put_in_pot.should be == amount_to_put_in_pot

    has_modifier = !modifier.nil?
    @patient.has_modifier?.should be == has_modifier
  end
  def instantiate_each_action_from_symbols(amount_to_put_in_pot=0,
                                           modifier=nil)
    PokerAction::LEGAL_SYMBOLS.each do |sym|
      modifier = if PokerAction::MODIFIABLE_ACTIONS.keys.include? sym
        modifier
      else
        nil
      end

      @patient = PokerAction.new(sym, {amount_to_put_in_pot: amount_to_put_in_pot, modifier: modifier})
      yield sym, modifier
    end
  end
  def instantiate_each_action_from_strings(amount_to_put_in_pot=0,
                                           modifier=nil)
    PokerAction::LEGAL_STRINGS.each do |string|
      modifier = if PokerAction::MODIFIABLE_ACTIONS.keys.include? string.to_sym
        modifier
      else
        nil
      end

      @patient = PokerAction.new(string, {amount_to_put_in_pot: amount_to_put_in_pot, modifier: modifier})
      yield string, modifier
    end
  end
  def instantiate_each_action_from_modified_strings(amount_to_put_in_pot=0,
                                                    modifier=nil)
    unless modifier
      modifier = mock('ChipStack')
      modifier.stubs(:to_s).returns('9001')
    end
    PokerAction::MODIFIABLE_ACTIONS.values.each do |char|
      string = PokerAction::LEGAL_ACTIONS.key(char).to_s
      modified_action = string + modifier.to_s

      @patient = PokerAction.new(modified_action, {amount_to_put_in_pot: amount_to_put_in_pot})
      yield string, modifier
    end
  end
  def instantiate_each_action_from_acpc_characters(amount_to_put_in_pot=0,
                                                   modifier=nil)
    PokerAction::LEGAL_ACPC_CHARACTERS.each do |char|
      modifier = if PokerAction::MODIFIABLE_ACTIONS.values.include? char
        modifier
      else
        nil
      end

      @patient = PokerAction.new(char, {amount_to_put_in_pot: amount_to_put_in_pot, modifier: modifier})
      yield char, modifier
    end
  end
  def instantiate_each_action_from_modified_acpc_characters(amount_to_put_in_pot=0,
                                                            modifier=nil)
    unless modifier
      modifier = mock('ChipStack')
      modifier.stubs(:to_s).returns('9001')
    end
    PokerAction::MODIFIABLE_ACTIONS.values.each do |char|
      modified_action = char + modifier.to_s

      @patient = PokerAction.new(modified_action, {amount_to_put_in_pot: amount_to_put_in_pot})
      yield char, modifier
    end
  end
end
