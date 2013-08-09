require 'acpc_poker_types/chip_stack'
require 'acpc_poker_types/hand'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/game_definition'

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

  attr_accessor :winnings

  # @param hand [Hand]
  # @param initial_chip_stack [#to_i]
  # @param ante [#to_i]
  def initialize(hand, initial_stack, ante)
    raise UnableToPayAnte if ante > initial_stack

    @hand = hand
    @initial_stack = ChipStack.new initial_stack
    @ante = ChipStack.new ante
    @actions = [[]]
    @winnings = ChipStack.new 0
  end

  def stack
    @initial_stack + balance
  end

  def balance
    @winnings - total_contribution
  end

  def contributions
    contribution_list = @actions.map do |actions_per_round|
      actions_per_round.inject(0) { |sum, action| sum += action.cost }
    end
    if contribution_list.empty?
      contribution_list << @ante
    else
      contribution_list[0] += @ante
    end

    contribution_list
  end

  def total_contribution
    @ante + @actions.flatten.inject(0) { |sum, action| sum += action.cost }
  end

  # @param amount_to_call [#to_r] The amount to call for this player
  # @param wager_illegal [Boolean]
  # @return [Array<PokerAction>] The list of legal actions for this player. If a wager is legal,
  # the smallest and largest possible wagers will be returned in the list.
  def legal_actions(
    in_round: round,
    amount_to_call: ChipStack.new(0),
    wager_illegal: false,
    betting_type: GameDefinition::BETTING_TYPES[:limit],
    min_wager_by: ChipStack.new(1)
  )
    l_actions = []
    return l_actions if inactive?

    if amount_to_call.to_r > 0
      l_actions << PokerAction.new(PokerAction::CALL, cost: amount_to_call)
      l_actions << PokerAction.new(PokerAction::FOLD)
    else
      l_actions << PokerAction.new(PokerAction::CHECK)
    end
    if !wager_illegal && wager_allowed_by_stack?(amount_to_call)
      min_wager_by_cost = [min_wager_by + amount_to_call.to_r, stack].min

      add_wager_actions = ->(wager_character) do
        l_actions << PokerAction.new(wager_character, cost: min_wager_by_cost)
        if all_in_allowed?(betting_type, min_wager_by_cost)
          l_actions << PokerAction.new(wager_character, cost: stack)
        end
      end

      if (
        amount_to_call.to_r > 0 || contributions[in_round].to_i > 0
      )
        add_wager_actions.call(PokerAction::RAISE)
      else
        add_wager_actions.call(PokerAction::BET)
      end
    end

    l_actions
  end

  def append_action!(action, round_num = round)
    raise Inactive if inactive?

    while @actions.length <= round_num
      @actions << []
    end

    @actions[round_num] ||= []
    @actions[round_num] << action

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

  def round
    @actions.length - 1
  end

  def wager_allowed_by_stack?(amount_to_call)
    stack > amount_to_call.to_r
  end

  def all_in_allowed?(betting_type, min_wager_by_cost)
    betting_type != GameDefinition::BETTING_TYPES[:limit] && min_wager_by_cost < stack
  end
end
end