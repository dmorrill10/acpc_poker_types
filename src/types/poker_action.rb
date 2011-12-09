
# System
require 'set'

# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

class PokerAction
   
   exceptions :illegal_poker_action
   
   # @return [Hash<Symbol, String>] Representations of legal actions.
   LEGAL_ACTIONS = {bet: 'r', call: 'c', check: 'c', fold: 'f', raise: 'r'}
   
   # @return [Set<Symbol>] The set of legal action symbols.
   LEGAL_SYMBOLS = Set.new LEGAL_ACTIONS.keys
   
   # @return [Set<String>] The set of legal action strings.
   LEGAL_STRINGS = Set.new LEGAL_ACTIONS.keys.map { |action| action.to_s }
   
   # @return [Set<String>] The set of legal ACPC action characters.
   LEGAL_ACPC_CHARACTERS = Set.new LEGAL_ACTIONS.values
   
   # @param [Symbol, String] action A representation of this action.
   # @raise IllegalPokerAction
   def initialize(action)
      if LEGAL_SYMBOLS.include? action
         @symbol = action
      elsif LEGAL_STRINGS.include? action
         @symbol = action.to_sym
      elsif LEGAL_ACPC_CHARACTERS.include? action
         @symbol = LEGAL_ACTIONS.key action
      end
      raise(IllegalPokerAction, action.to_s) unless @symbol
   end
   
   # @return [Symbol]
   def to_sym
      @symbol
   end
   
   # @return [String] String representation of this rank.
   def to_s
      @symbol.to_s
   end
   
   # @return [String] ACPC character representation of this rank.
   def to_acpc
      LEGAL_ACTIONS[@symbol]
   end
end
