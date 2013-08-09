require 'delegate'

require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/hand_player'

# Model to parse and manage information from a given match state string.
module AcpcPokerTypes

class HandPlayerGroup < DelegateClass(Array)
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
    return nil if all? { |player| player.inactive? }

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

  def next_to_act(acting_player_position=-1)
    position_of_first_active_player(
      next_player_position(acting_player_position)
    )
  end

  # @return [Integer] The number of wagers this round
  def num_wagers(round)
    inject(0) do |sum, pl|
      next sum if round >= pl.actions.length

      sum += pl.actions[round].count do |ac|
        PokerAction::MODIFIABLE_ACTIONS.include?(ac.action)
      end
    end
  end

  # @return [Array<PokerAction>] The legal actions for the next player to act.
  def legal_actions(acting_player_position, round, game_def, min_wager_by)
    @players[acting_player_position].legal_actions(
      in_round: round,
      amount_to_call: amount_to_call(acting_player_position),
      wager_illegal: num_wagers(round) >= game_def.max_number_of_wagers[round],
      betting_type: game_def.betting_type,
      min_wager_by: min_wager_by
    )
  end
end
end