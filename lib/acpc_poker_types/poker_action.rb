require 'delegate'
require 'set'

require 'acpc_poker_types/chip_stack'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module BlankRefinement
  refine Object do
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end
  refine NilClass do
    def blank?
      true
    end
    def strip
      self
    end
  end
  refine Array do
    alias_method :blank?, :empty?
  end
  refine String do
    def blank?
      self !~ /\S/
    end
  end
end
using BlankRefinement


module AcpcPokerTypes

class PokerAction < DelegateClass(String)
  exceptions :illegal_action, :illegal_modification

  BET = 'b'
  CALL = 'c'
  CHECK = 'k'
  FOLD = 'f'
  RAISE = 'r'

  ACTIONS = Set.new [BET, CALL, CHECK, FOLD, RAISE]

  # @return [Set<String>] The set of legal ACPC action characters.
  CANONICAL_ACTIONS = Set.new [CALL, FOLD, RAISE]

  MODIFIABLE_ACTIONS = Set.new [BET, RAISE]

  CONCATONATED_ACTIONS = ACTIONS.to_a.join

  # @return [Rational] The amount that the player taking this action needs to put in the pot.
  #  Could be negative to imply the acting player takes chips from the pot.
  attr_reader :cost

  # @return [String] A modifier for the action (i.e. a bet or raise size).
  attr_reader :modifier

  # @return [String] Action character
  attr_reader :action
  alias_method :to_acpc_character, :action

  # @return [Boolean] Whether or not the pot has been added to this round before this action.
  attr_reader :pot_gained_chips

  # @param [Symbol, String] action A representation of this action.
  # @param modifier [String] A modifier to attach to this action such as a wager size.
  # @param cost [#to_f] The amount this action costs to the acting player.
  # @raise IllegalAction
  def initialize(action, modifier: nil, cost: 0)
    @modifier = nil
    validate_action!(action, modifier.strip)
    @cost = cost.to_f

    super to_s
  end

  # @return [String] String representation of this action.
  # @param pot_gained_chips [Boolean] Whether or not the pot had gained chips before this action.
  # Defaults to +pot_gained_chips?+.
  # @param player_sees_wager [Boolean] Whether or not the player is reacting to a wager.
  # Defaults to the value of +player_sees_wager?+.
  def to_s(pot_gained_chips: pot_gained_chips?, player_sees_wager: player_sees_wager?)
    combine_action_and_modifier(
      if @action == FOLD
        @action
      elsif @action == BET || @action == RAISE
        if pot_gained_chips then RAISE else BET end
      elsif @action == CALL || @action == CHECK
        if player_sees_wager then CALL else CHECK end
      end
    )
  end

  alias_method :to_acpc, :to_s

  # @return [Boolean] +true+ if this action has a modifier, +false+ otherwise.
  def has_modifier?
    @modifier && !@modifier.blank?
  end

  private

  def pot_gained_chips?
    if @action == FOLD || @action == RAISE || @action == CALL
      true
    elsif @action == CHECK
      # Could be true or false, but doesn't matter for the purpose of
      # printing a check properly
      nil
    else
      false
    end
  end

  def player_sees_wager?
    if @action == FOLD || @action == CALL
      true
    elsif @action == RAISE
      # Could be true or false, but doesn't matter for the purpose of
      # printing a raise properly
      nil
    else
      false
    end
  end

  def combine_action_and_modifier(action=@action, modifier=@modifier)
    "#{action}#{modifier}"
  end

  def validate_action!(action, given_modifier)
    action_string = action.to_s
    raise IllegalAction if action_string.empty?
    @action = action_string[0]
    raise IllegalAction unless ACTIONS.include?(@action)
    @modifier = action_string[1..-1].strip unless action_string.length < 2

    if !given_modifier.blank? && !@modifier.blank?
      raise(
        IllegalModification,
        "in-place modifier: #{@modifier}, explicit modifier: #{given_modifier}"
      )
    end

    @modifier = if !@modifier.blank?
      @modifier
    elsif !given_modifier.blank?
      given_modifier
    end

    validate_modifier

    self
  end

  def validate_modifier
    unless @modifier.nil? || @modifier.blank? || MODIFIABLE_ACTIONS.include?(@action)
      raise(IllegalModification, "Illegal modifier: #{@modifier}")
    end
  end
end
end
