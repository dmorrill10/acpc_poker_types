
# System
require 'set'

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Local classes
require File.expand_path('../chip_stack', __FILE__)

class PokerAction
   
   exceptions :illegal_poker_action, :illegal_poker_action_modification
   
   # @return A modifier for the action (i.e. a bet or raise size).
   attr_reader :modifier
   
   # @return [Hash<Symbol, String>] Representations of legal actions.
   # @todo support overloaded actions like bet and check LEGAL_ACTIONS = {bet: 'r', call: 'c', check: 'c', fold: 'f', raise: 'r'}
   LEGAL_ACTIONS = {bet: 'b', call: 'c', check: 'k', fold: 'f', raise: 'r'}
   
   # @return [Set<Symbol>] The set of legal action symbols.
   LEGAL_SYMBOLS = Set.new LEGAL_ACTIONS.keys
   
   # @return [Set<String>] The set of legal action strings.
   LEGAL_STRINGS = Set.new LEGAL_ACTIONS.keys.map { |action| action.to_s }
   
   # @return [Set<String>] The set of legal ACPC action characters.
   LEGAL_ACPC_CHARACTERS = Set.new LEGAL_ACTIONS.values
   
   # @return [Hash<Symbol, String>] Representations of the legal ACPC action characters that may be accompanied by a modifier.
   MODIFIABLE_ACTIONS = LEGAL_ACTIONS.select { |sym, char| 'r' == char || 'b' == char }
   
   # @return [Hash] Map of general actions to more specific actions (e.g. call to check and raise to bet).
   HIGH_RESOLUTION_ACTION_CONVERSION = {call: :check, raise: :bet, fold: :fold, check: :check, bet: :bet}
   
   # @param [Symbol, String] action A representation of this action.
   # @param [ChipStack, NilClass] modifier A modifier for the action (i.e. a bet or raise size).
   # @raise IllegalPokerAction
   def initialize(action, modifier=nil, acting_player_sees_wager=true)
      (@symbol, @modifier) = validate_action action, modifier, acting_player_sees_wager
   end
   
   def ==(other_action)
      to_sym == other_action.to_sym && to_s == other_action.to_s && to_acpc == other_action.to_acpc && @modifier == other_action.modifier
   end
   
   # @return [Boolean] +true+ if this action has a modifier, +false+ otherwise.
   def has_modifier?
      !@modifier.nil?
   end
   
   # @return [Symbol]
   def to_sym
      @symbol
   end
   
   # @todo Should probably display the modifier here as well.
   # @return [String] String representation of this action.
   def to_s
      @symbol.to_s
   end
   
   # @return [String] Full ACPC representation of this action.
   def to_acpc
      LEGAL_ACTIONS[@symbol] + @modifier.to_s
   end
   
   # @return [String] ACPC character representation of this action.
   def to_acpc_character
      LEGAL_ACTIONS[@symbol]
   end
   
   private
   
   def validate_action(action, modifier, acting_player_sees_wager)
      action_type = nil
      in_place_modifier = nil
      if action.to_s.match(/^(#{(LEGAL_SYMBOLS.to_a.map{ |sym| sym.to_s }).join('|')})\s*(\d*)$/)
      elsif action.to_s.match(/^(#{LEGAL_STRINGS.to_a.join('|')})\s*(\d*)$/)
      elsif action.to_s.match(/^([#{LEGAL_ACPC_CHARACTERS.to_a.join('')}])\s*(\d*)$/)
      else
         raise(IllegalPokerAction, action.to_s)
      end
      action_type, in_place_modifier = $1, $2
      
      raise(IllegalPokerActionModification, "in-place modifier: #{in_place_modifier}, explicit modifier: #{modifier}") if modifier && !in_place_modifier.empty?
      
      modifier_to_use = if modifier
         modifier
      elsif !in_place_modifier.empty?
         ChipStack.new in_place_modifier.to_i
      end
      
      symbol_betting_type = LEGAL_ACTIONS.key(action_type) || action_type.to_sym
      action_symbol = increase_resolution_of_action(symbol_betting_type, acting_player_sees_wager)
      
      raise(IllegalPokerAction, 'Players may only fold if they are faced with a wager.') if :fold == symbol_betting_type && !acting_player_sees_wager
      
      action_modifier = validate_modifier(modifier_to_use, action_symbol)
      [action_symbol, action_modifier]
   end
   
   def validate_modifier(modifier, action_symbol)
      raise(IllegalPokerActionModification, modifier.to_s) unless modifier.nil? || MODIFIABLE_ACTIONS.keys.include?(action_symbol)
      modifier
   end
   
   def increase_resolution_of_action(action, acting_player_sees_wager)
      if acting_player_sees_wager
         action
      else
         HIGH_RESOLUTION_ACTION_CONVERSION[action]
      end
   end
end
