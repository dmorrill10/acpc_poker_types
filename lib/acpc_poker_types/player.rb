require 'acpc_poker_types/chip_stack'
require 'acpc_poker_types/hand'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

# Class to model a player.
module AcpcPokerTypes
  class Player
    exceptions :incorrect_number_of_player_names

    def self.create_players(player_names, game_def)
      if game_def.number_of_players != player_names.length
        raise(
          IncorrectNumberOfPlayerNames,
          "#{player_names.length} names for #{game_def.number_of_players} players"
        )
      end

      game_def.number_of_players.times.inject([]) do |players, seat|
        players << AcpcPokerTypes::Player.join_match(
          player_names[seat],
          seat,
          AcpcPokerTypes::ChipStack.new(game_def.chip_stacks[seat])
        )
      end
    end

    # @return [String] The name of this player.
    attr_reader :name

    # @return [Integer] This player's seat.  This is a 0 indexed
    #  number that represents the order that this player joined the dealer.
    attr_reader :seat

    # @return [AcpcPokerTypes::ChipStack] This player's chip stack.
    attr_reader :chip_stack

    # @return [Array<AcpcPokerTypes::ChipStack>] This player's contribution to the pot in the
    #  current hand, organized by round.
    attr_reader :chip_contributions

    # @return [Integer] The amount this player has won or lost in the current
    #  match.  During a hand, this is a projected amount assuming that this
    #  player loses.  Positive amounts are winnings, negative amounts are losses.
    attr_reader :chip_balance

    # @return [Hand] This player's hole cards or nil if this player is not
    #  holding cards.
    # @example (see MatchState#users_hole_cards)
    attr_reader :hole_cards

    # @return [Array<Array<String>>] The list of actions this player has taken in
    #  the current hand, separated by round.
    attr_reader :actions_taken_this_hand

    class << self; alias_method(:join_match, :new) end

    # @todo These comments don't work as expected
    # @param [String] name This players name.
    # @param [Integer] seat (see #seat)
    # @param [#to_i] chip_stack (see #chip_stack)
    def initialize(name, seat, chip_stack)
      @name = name
      @seat = seat
      @chip_balance = 0
      @chip_stack = chip_stack
      @chip_contributions = [0]

      @actions_taken_this_hand = [[]]
    end

    def ==(other)
      equal_on_public_info?(other) &&
      @hole_cards == other.hole_cards
    end

    def equal_on_public_info?(other)
      @name == other.name &&
      @seat == other.seat &&
      @chip_stack == other.chip_stack &&
      @chip_contributions == other.chip_contributions &&
      @chip_balance == other.chip_balance &&
      @actions_taken_this_hand == other.actions_taken_this_hand
    end

    # @param [#to_i] blind_amount The blind amount for this player to pay.
    # @param [#to_i] chip_stack (see #chip_stack)
    # @param [Hand] hole_cards (see #hole_cards)
    def start_new_hand!(blind=AcpcPokerTypes::ChipStack.new(0), chip_stack=@chip_stack, hole_cards=AcpcPokerTypes::Hand.new)
      @chip_stack = chip_stack
      @hole_cards = hole_cards
      @actions_taken_this_hand = []
      @chip_contributions = []

      start_new_round!

      pay_blind! blind
    end

    def start_new_round!
      @actions_taken_this_hand << []
      @chip_contributions << 0

      self
    end

    # @param [PokerAction] action The action to take.
    # @param pot_gained_chips [Boolean] Whether or not the pot had gained chips before this action. Defaults to true.
    # @param sees_wager [Boolean] Whether or not the player is reacting to a wager.
    #   Defaults to the value of +pot_gained_chips+.
    def take_action!(action, pot_gained_chips: true, sees_wager: pot_gained_chips)
      @actions_taken_this_hand.last << action.to_s(pot_gained_chips: pot_gained_chips, player_sees_wager: sees_wager)

      take_from_chip_stack! action.cost.to_r
    end

    # @return [Boolean] Reports whether or not this player has folded.
    def folded?
      @actions_taken_this_hand.any? do |actions|
        actions.any? { |action| action == AcpcPokerTypes::PokerAction::FOLD }
      end
    end

    # @return [Boolean] Reports whether or not this player is all-in.
    def all_in?
      0 == @chip_stack
    end

    # @return [Boolean] Whether or not this player is active (has not folded
    #     or gone all-in). +true+ if this player is active, +false+ otherwise.
    def active?
      !(folded? || all_in?)
    end

    # @return [Integer] The current round, zero indexed.
    def round
      @actions_taken_this_hand.length - 1
    end

    # Adjusts this player's state when it takes chips from the pot.
    # @param [Integer] chips The number of chips this player has won from the pot.
    def take_winnings!(chips)
      @chip_contributions << 0

      add_to_stack! chips
    end

    def assign_cards!(hole_cards)
      @hole_cards = hole_cards

      self
    end

    private

    # @param [#to_i] blind_amount The blind amount for this player to pay.
    def pay_blind!(blind_amount)
      take_from_chip_stack! blind_amount
    end

    def add_to_stack!(chips)
      @chip_stack += chips
      @chip_balance += chips.to_r
      @chip_contributions[-1] -= chips.to_r

      self
    end

    # Take chips away from this player's chip stack.
    # @param (see AcpcPokerTypes::ChipStack#-)
    # @raise (see AcpcPokerTypes::ChipStack#-)
    def take_from_chip_stack!(number_of_chips)
      @chip_stack -= number_of_chips
      @chip_balance -= number_of_chips.to_r
      @chip_contributions[-1] += number_of_chips.to_r

      self
    end
  end
end