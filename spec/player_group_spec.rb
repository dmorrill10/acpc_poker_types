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
#     it 'calculates proper player states' do
#       wager_size = 10
#       x_game_def = GameDefinition.new(
#         first_player_positions: [3, 2, 2],
#         chip_stacks: [100, 200, 150],
#         blinds: [0, 10, 5],
#         raise_sizes: [wager_size]*3,
#         number_of_ranks: 3
#       )
#       x_actions = [
#         [
#           [
#             PokerAction.new(PokerAction::RAISE, cost: wager_size + 10),
#           ],
#           [
#             PokerAction.new(PokerAction::CHECK)
#           ],
#           [
#             PokerAction.new(PokerAction::FOLD)
#           ]
#         ],
#         [
#           [
#             PokerAction.new(PokerAction::CALL, cost: wager_size)
#           ],
#           [
#             PokerAction.new(PokerAction::CHECK)
#           ],
#           [
#             PokerAction.new(PokerAction::BET, cost: wager_size),
#             PokerAction.new(PokerAction::CALL, cost: wager_size)
#           ]
#         ],
#         [
#           [
#             PokerAction.new(PokerAction::CALL, cost: 5),
#             PokerAction.new(PokerAction::CALL, cost: wager_size)
#           ],
#           [
#             PokerAction.new(PokerAction::CHECK)
#           ],
#           [
#             PokerAction.new(PokerAction::RAISE, cost: 2 * wager_size)
#           ]
#         ]
#       ]
#       x_contributions = x_actions.map_with_index do |actions_per_player, i|
#         actions_per_player.map do |actions_per_round|
#           actions_per_round.inject(0) { |sum, action| sum += action.cost }
#         end.unshift(x_game_def.blinds[i])
#       end
#       num_players = 3
#       (0..num_players-1).each do |position|
#         x_hands = num_players.times.map { Hand.new }

#         x_hands[position] = Hand.from_acpc 'Ah'

#         hand_string = x_hands.inject('') do |hand_string, hand|
#           hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
#         end[0..-2]

#         x_match_state = MatchState.parse(
# "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc:#{hand_string}"
#         )

#         patient = PlayerGroup.new(x_game_def, x_match_state)

#         patient.game_def.must_equal x_game_def
#         patient.match_state.must_equal x_match_state

#         patient.each_with_index do |player, pos|
#           player.initial_stack.must_equal x_game_def.chip_stacks[pos]
#           player.ante.must_equal x_game_def.blinds[pos]
#           player.hand.must_equal x_hands[pos]
#           player.actions.must_equal x_actions[pos]
#           player.contributions.must_equal x_contributions[pos]
#         end
#       end
#     end
  end

  # @return [Hand] An arbitrary hole card hand.
  def arbitrary_hole_card_hand
    Hand.from_acpc('AhKs')
  end
end