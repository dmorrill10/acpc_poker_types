require 'delegate'

require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/hand_player'

# Model to parse and manage information from a given match state string.
module AcpcPokerTypes

class PlayerGroup < DelegateClass(Array)
  attr_reader :players

  def initialize(all_hands, stacks, blinds)
    @players = all_hands.length.times.map do |i|
      HandPlayer.new all_hands[i], stacks[i], blinds[i]
    end

    super @players
  end

  def next_player_position(acting_player_position=-1)
    (acting_player_position + 1) % length
  end

  def position_of_first_active_player(acting_player_position=0)
    raise NoPlayerCouldHaveActed if all? { |player| player.inactive? }

    # This must eventually exit because of the above assertion
    while @players[acting_player_position].inactive?
      acting_player_position = next_player_position(acting_player_position)
    end
    acting_player_position
  end

  def action_cost(acting_player_position, action, min_wager)
    case action.to_s[0]
    when PokerAction::CALL
      amount_to_call acting_player_position
    when PokerAction::RAISE
      if action.modifier
        action.modifier.to_i - players[acting_player_position].total_contribution
      else
        min_wager + amount_to_call(acting_player_position)
      end
    else
      0
    end
  end

  def amount_to_call(acting_player_position)
    ChipStack.new(
      [
        (
          map do |player|
            player.total_contribution
          end
        ).max - players[acting_player_position].total_contribution,
        @players[acting_player_position].stack
      ].min
    )
  end
end
end