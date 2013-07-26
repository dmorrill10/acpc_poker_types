require 'acpc_poker_types/chip_stack'
require 'acpc_poker_types/hand'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerTypes

# Class to model a player during a hand from information in a +MatchState+
class HandPlayer
  exceptions :unable_to_pay_ante, :inactive

  # @return [AcpcPokerTypes::ChipStack] This player's chip stack at the beginning of the
  # hand before paying their ante.
  attr_reader :initial_stack

  # @return [AcpcPokerTypes::ChipStack] The ante this player paid at the beginning of
  # the hand.
  attr_reader :ante

  # @return [Hand] This player's hole cards or nil if this player is not
  # holding cards.
  attr_reader :hand

  # @return [Array<PokerAction>] The actions this player has taken
  attr_reader :actions

  # @param hand [Hand]
  # @param initial_chip_stack [#to_i]
  # @param ante [#to_i]
  def initialize(hand, initial_stack, ante)
    raise UnableToPayAnte if ante > initial_stack

    @hand = hand
    @initial_stack = ChipStack.new initial_stack
    @ante = ChipStack.new ante
    @actions = []
  end

  def stack
    @initial_stack - (@ante + contributions)
  end

  def contributions
    @actions.flatten.inject(0) { |sum, action| sum += action.cost }
  end

  def append_action!(action, round = @actions.length - 1)
    raise Inactive if inactive?

    @actions[round] ||= []
    @actions[round] << action

    self
  end

  def inactive?
    folded? || all_in?
  end

  def all_in?
    stack <= 0
  end

  def folded?
    @actions.flatten.last == PokerAction::FOLD
  end
end

end