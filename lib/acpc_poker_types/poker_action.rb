require 'set'

require 'acpc_poker_types/chip_stack'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerTypes
  class PokerAction
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
    # @param [Hash] context The context in which this action is being made. Recognized keys include +:modifier+,
    #  +:pot_gained_chips+, and +:cost+.
    # @raise IllegalAction
    def initialize(action, modifier: nil, cost: AcpcPokerTypes::ChipStack.new(0))
      validate_action!(action, modifier)
      @cost = cost
    end

    def ==(other_action)
      to_s == other_action.to_s
    end

    # @return [String] String representation of this action.
    # @param pot_gained_chips [Boolean] Whether or not the pot had gained chips before this action. Defaults to true.
    # @param player_sees_wager [Boolean] Whether or not the player is reacting to a wager.
    #   Defaults to the value of +pot_gained_chips+.
    def to_s(pot_gained_chips: true, player_sees_wager: pot_gained_chips)
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
      !@modifier.nil?
    end

    private

    def combine_action_and_modifier(action=@action, modifier=@modifier)
      "#{action}#{modifier}"
    end

    def validate_action!(action, given_modifier)
      action_string = action.to_s
      raise IllegalAction if action_string.empty?
      @action = action_string[0]
      raise IllegalAction unless ACTIONS.include?(@action)
      @modifier = action_string[1..-1] unless action_string.length < 2

      if given_modifier && @modifier && !@modifier.empty?
        raise(
          IllegalModification,
          "in-place modifier: #{@modifier}, explicit modifier: #{given_modifier}"
        )
      end

      @modifier = if @modifier && !@modifier.empty?
        @modifier
      elsif given_modifier
        given_modifier
      end

      validate_modifier

      self
    end

    def validate_modifier
      raise(IllegalModification, "Illegal modifier: #{@modifier}") unless @modifier.nil? || AcpcPokerTypes::PokerAction::MODIFIABLE_ACTIONS.include?(@action)
    end
  end
end