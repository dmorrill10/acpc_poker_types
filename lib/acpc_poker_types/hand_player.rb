require 'acpc_poker_types/chip_stack'
require 'acpc_poker_types/hand'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerTypes

# Class to model a player during a hand.  
class HandPlayer
  exceptions :unable_to_pay_ante
  
  # @return [AcpcPokerTypes::ChipStack] This player's chip stack at the beginning of the 
  # hand before paying their ante.
  attr_reader :initial_stack

  # @return [AcpcPokerTypes::ChipStack] The ante this player paid at the beginning of 
  # the hand.
  attr_reader :ante
  
  # @return [Hand] This player's hole cards or nil if this player is not
  # holding cards.
  attr_reader :hand

  # @param hand [Hand]
  # @param initial_chip_stack [#to_i]
  # @param ante [#to_i]
  def initialize(hand, initial_stack, ante)
    raise UnableToPayAnte if ante > initial_stack
    
    @hand = hand
    @initial_stack = ChipStack.new initial_stack
    @ante = ChipStack.new ante
  end
  
  def stack
    @stack ||= @initial_stack - @ante
  end
end

end