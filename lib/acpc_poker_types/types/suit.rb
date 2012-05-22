
# Local modules
require File.expand_path('../../acpc_poker_types_defs', __FILE__)

# Local mixins
require File.expand_path('../../mixins/utils', __FILE__)

class Suit
   include AcpcPokerTypesDefs
   
   exceptions :not_a_recognized_suit
   
   # @return [Symbol] This suit's symbol.
   attr_reader :symbol
   
   # @param [Symbol] suit This suit's symbol.
   # @raise (see #sanity_check_suit)
   def initialize(symbol)
      sanity_check_suit symbol
      
      @symbol = symbol
   end
   
   # @return [Integer] Integer ACPC representation of this suit.
   def to_i
      CARD_SUIT_NUMBERS[to_s]
   end
   
   # @return [String] String representation of this suit.
   def to_s
      CARD_SUITS[@symbol][:acpc_character]
   end
   
   # @return [String] Raw HTML character representation of this suit.
   def to_html
      CARD_SUITS[@symbol][:html_character]
   end
   
   private
   
   # @raise NotARecognizedSuit
   def sanity_check_suit(suit)
      raise NotARecognizedSuit, suit.to_s unless CARD_SUITS[suit]
   end
end