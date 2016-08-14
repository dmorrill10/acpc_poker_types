require_relative 'support/spec_helper'

require_relative "../lib/acpc_poker_types/hand_player_group"
require_relative "../lib/acpc_poker_types/hand"

using MapWithIndex

include AcpcPokerTypes

describe HandPlayerGroup do
  describe '::new' do
    it 'creates HandPlayers at the start of a hand' do
      stacks = [100, 200, 150]
      blinds = [0, 10, 5]
      num_players = 3
      (0..num_players-1).each do |position|
        hands = num_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        HandPlayerGroup.new(
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
