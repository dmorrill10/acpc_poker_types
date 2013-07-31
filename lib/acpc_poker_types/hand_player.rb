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
    @actions = [[]]
  end

  def stack
    @initial_stack - total_contribution
  end

  def contributions
    @actions.map do |actions_per_round|
      actions_per_round.inject(0) { |sum, action| sum += action.cost }
    end.unshift @ante
  end

  def total_contribution
    @ante + @actions.flatten.inject(0) { |sum, action| sum += action.cost }
  end

  # @param amount_to_call [#to_r] The amount to call for this player
  # @param wager_illegal [Boolean]
  # @return [Array<PokerAction>] The list of legal actions for this player. If a wager is legal,
  # the largest possible wager will be returned in the list.
  def legal_actions(
    round,
    amount_to_call: ChipStack.new(0),
    wager_illegal: false
  )
    l_actions = []
    return l_actions if inactive?

    if amount_to_call.to_r > 0
      l_actions << PokerAction.new(PokerAction::CALL) << PokerAction.new(PokerAction::FOLD)
    else
      l_actions << PokerAction.new(PokerAction::CHECK)
    end
    if !wager_illegal && stack > amount_to_call.to_r
      l_actions << if contributions[round] > 0 || amount_to_call.to_r > 0
        PokerAction.new(PokerAction::RAISE, cost: stack - amount_to_call.to_r)
      else
        PokerAction.new(PokerAction::BET, cost: stack - amount_to_call.to_r)
      end
    end

    l_actions
  end

  # @param round [Integer] The round in which the largest wager by size is desired.
  # defaults to +nil+.
  # @return [ChipStack] The largest wager by size this player has made.
  # Checks only in the specified +round+ or over the entire hand if round is +nil+.
  def largest_wager_by(round=nil)
    # @todo
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