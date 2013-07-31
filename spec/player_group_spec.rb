require_relative 'support/spec_helper'

# require 'acpc_dealer'

require_relative "../lib/acpc_poker_types/player_group"
# require_relative "../lib/acpc_poker_types/game_definition"
# require_relative "../lib/acpc_poker_types/match_state"
# require_relative "../lib/acpc_poker_types/poker_action"
require_relative "../lib/acpc_poker_types/hand"
# require_relative "../lib/acpc_poker_types/card"
# require_relative "../lib/acpc_poker_types/acpc_dealer_data/poker_match_data"

module MapWithIndex
  refine Array do
    def map_with_index
      i = 0
      map do |elem|
        result = yield elem, i
        i += 1
        result
      end
    end
  end
end
using MapWithIndex

include AcpcPokerTypes

describe PlayerGroup do
  describe '::new' do
    it 'creates HandPlayers at the start of a hand' do
      stacks = [100, 200, 150]
      blinds = [0, 10, 5]
      num_players = 3
      (0..num_players-1).each do |position|
        hands = num_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        PlayerGroup.new(
          hands,
          stacks,
          blinds
        ).each_with_index do |player, pos|
          player.initial_stack.must_equal stacks[pos]
          player.ante.must_equal blinds[pos]
          player.hand.must_equal hands[pos]
        end
      end
    end
  end

  # @return [Hand] An arbitrary hole card hand.
  def arbitrary_hole_card_hand
    Hand.from_acpc('AhKs')
  end
end