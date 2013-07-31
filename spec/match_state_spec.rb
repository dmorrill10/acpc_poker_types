require_relative 'support/spec_helper'

require 'acpc_dealer'

require_relative "../lib/acpc_poker_types/match_state"
require_relative "../lib/acpc_poker_types/poker_action"
require_relative "../lib/acpc_poker_types/rank"
require_relative "../lib/acpc_poker_types/suit"
require_relative "../lib/acpc_poker_types/hand"
require_relative "../lib/acpc_poker_types/card"
require_relative "../lib/acpc_poker_types/game_definition"

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

describe MatchState do
  describe '#parse' do
    it "parses every possible limit action" do
      partial_match_state = MatchState::LABEL + ":1:1:"
      hole_cards = arbitrary_hole_card_hand
      PokerAction::CANONICAL_ACTIONS.each do |action|
        match_state = partial_match_state + action + ":" + hole_cards.to_acpc
        patient = test_match_state_success match_state
        patient.last_action.to_s.must_equal action
      end
    end
    it "parses every possible hole card hand" do
      partial_match_state = MatchState::LABEL + ":2:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + hand.to_acpc + '|'

        test_match_state_success match_state
      end
    end
    it "parses opponent hole card hands in a two player game where the user is not the dealer" do
      partial_match_state = MatchState::LABEL + ":0:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + arbitrary_hole_card_hand.to_acpc + '|' + hand.to_acpc

        patient = test_match_state_success match_state

        (patient.opponent_hands.map do |opponent_hand|
          opponent_hand.to_acpc
        end).must_equal [hand.to_acpc]
      end
    end
    it "parses opponent hole card hands in a two player game where the user is the dealer" do
      partial_match_state = MatchState::LABEL + ":1:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + hand.to_acpc + '|' + arbitrary_hole_card_hand.to_acpc

        patient = test_match_state_success match_state

        (patient.opponent_hands.map do |opponent_hand|
           opponent_hand.to_acpc
        end).must_equal [hand.to_acpc]
      end
    end
    it 'parses board cards properly for the flop' do
      partial_match_state = MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc

      community_cards = '/AhKdQc'
      flop_match_state = partial_match_state + community_cards

      patient = MatchState.parse flop_match_state

      patient.community_cards.to_acpc.must_equal community_cards
    end
    it 'parses board cards properly for the turn' do
      partial_match_state = MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc
      community_cards = '/AhKdQc/Jd'
      turn_match_state = partial_match_state + community_cards

      patient = MatchState.parse turn_match_state

      patient.community_cards.to_acpc.must_equal community_cards
    end
    it 'parses board cards properly for the river' do
      partial_match_state = MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc
      community_cards = '/AhKdQc/Jd/Th'
      river_match_state = partial_match_state + community_cards

      patient = MatchState.parse river_match_state

      patient.community_cards.to_acpc.must_equal community_cards
    end
    it "parses a valid two player final match state" do
      partial_match_state = MatchState::LABEL + ":20:22:"
      all_actions = PokerAction::CANONICAL_ACTIONS.to_a.join ''
      betting = all_actions
      number_of_rounds = 100
      (number_of_rounds-1).times do
        betting += "/#{all_actions}"
      end
      community_cards = arbitrary_roll_out number_of_rounds
      hands = arbitrary_hole_card_hand.to_acpc + "|" + arbitrary_hole_card_hand.to_acpc

      match_state = partial_match_state + betting + ":" + hands + community_cards

      test_match_state_success match_state
    end
    it "parses a valid three player final match state" do
      partial_match_state = MatchState::LABEL + ":20:22:"
      all_actions = PokerAction::CANONICAL_ACTIONS.to_a.join ''
      betting = all_actions
      number_of_rounds = 100
      (number_of_rounds-1).times do
        betting += "/#{all_actions}"
      end
      community_cards = arbitrary_roll_out number_of_rounds
      hands = arbitrary_hole_card_hand.to_s + "|" +
        arbitrary_hole_card_hand.to_s + "|" + arbitrary_hole_card_hand.to_s

      match_state = partial_match_state + betting + ":" + hands + community_cards

      test_match_state_success match_state
    end
  end

  describe '#round' do
    it "properly reports the current round number" do
      partial_match_state = MatchState::LABEL + ":0:0:"
      betting = ""
      hand = arbitrary_hole_card_hand
      100.times do |i|
        match_state = partial_match_state + betting + ':|' + hand
        patient = test_match_state_success match_state
        patient.round.must_equal i

        betting += "c/"
      end
    end
  end

  it 'reports the correct number of players' do
    expected_number_of_players = 0
    10.times do |i|
      expected_number_of_players += 1
      hands = []
      expected_number_of_players.times do |j|
        if i.odd? and j.odd?
          hands.push ''
          next
        end
        hands.push arbitrary_hole_card_hand.to_acpc
      end
      match_state = MatchState::LABEL + ':1:1::' + hands.join('|')

      patient = test_match_state_success match_state
      patient.number_of_players.must_equal expected_number_of_players
    end
  end

  describe '#last_action, #round_in_which_last_action_taken, and #first_state_of_first_round' do
    it 'returns +nil+ if no previous action exists, or true in the case of #first_state_of_first_round' do
      initial_match_state = "#{MatchState::LABEL}:1:1::#{arbitrary_hole_card_hand}"
      patient = MatchState.parse initial_match_state
      patient.last_action.must_be_nil
      patient.round_in_which_last_action_taken.must_be_nil
      patient.first_state_of_first_round?.must_equal true
    end
    it 'works properly if a previous action exists' do
      PokerAction::CANONICAL_ACTIONS.each do |first_action|
        PokerAction::CANONICAL_ACTIONS.each do |second_action|
          PokerAction::CANONICAL_ACTIONS.each do |third_action|
            partial_match_state = "#{MatchState::LABEL}:1:1:"

            partial_match_state += first_action
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = MatchState.parse match_state
            patient.last_action.must_equal PokerAction.new(first_action)
            patient.round_in_which_last_action_taken.must_equal 0
            patient.first_state_of_first_round?.must_equal false

            partial_match_state += "#{second_action}/"
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = MatchState.parse match_state
            patient.last_action.must_equal PokerAction.new(second_action)
            patient.round_in_which_last_action_taken.must_equal 0
            patient.first_state_of_first_round?.must_equal false

            partial_match_state += third_action
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = MatchState.parse match_state
            patient.last_action.must_equal PokerAction.new(third_action)
            patient.round_in_which_last_action_taken.must_equal 1
            patient.first_state_of_first_round?.must_equal false
          end
        end
      end
    end
  end
  describe "#receive_matchstate_string" do
    it 'receives matchstate strings properly' do
      skip 'Fix PokerMatchData suite first'

      @connection = mock 'Socket'
      MatchLog.all.each do |log_description|
        match = AcpcDealerData::PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          20
        )
        match.for_every_seat! do |seat|
          match.for_every_hand! do
            match.for_every_turn! do
              @connection.expects(:gets).returns(match.current_hand.current_match_state.to_s)

              MatchState.receive(@connection).must_equal match.current_hand.current_match_state
            end
          end
        end
      end
    end
  end
  describe '#betting_sequence' do
    it 'works' do
      MatchState.parse(
        "#{MatchState::LABEL}:0:0:crcc/ccc/rrfc:AhKs|"
      ).betting_sequence.must_equal [
        [
          PokerAction.new(PokerAction::CALL),
          PokerAction.new(PokerAction::RAISE),
          PokerAction.new(PokerAction::CALL),
          PokerAction.new(PokerAction::CALL)
        ],
        [
          PokerAction.new(PokerAction::CALL),
          PokerAction.new(PokerAction::CALL),
          PokerAction.new(PokerAction::CALL)
        ],
        [
          PokerAction.new(PokerAction::RAISE),
          PokerAction.new(PokerAction::RAISE),
          PokerAction.new(PokerAction::FOLD),
          PokerAction.new(PokerAction::CALL)
        ]
      ]
    end
  end
  describe '#players_at_hand_start' do
    it 'returns HandPlayers with states set at the beginning of the hand' do
      stacks = [100, 200, 150]
      blinds = [0, 10, 5]
      num_players = 3
      (0..num_players-1).each do |position|
        hands = num_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
"#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc:#{hand_string}"

        MatchState.new(
          match_state
        ).players_at_hand_start(
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
  describe '#every_action' do
    it 'yields every action, plus the round number, and the acting player position relative to the dealer' do
      wager_size = 10
      x_game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*4,
        number_of_ranks: 3
      )

      (0..x_game_def.number_of_players-1).each do |position|
        x_actions = [
          {
            action: PokerAction.new(PokerAction::CALL, cost: 5),
            round: 0,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::RAISE, cost: wager_size + 10),
            round: 0,
            acting_player_position: 0
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 0,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 0,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 1,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 1,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 1,
            acting_player_position: 0
          },
          {
            action: PokerAction.new(PokerAction::BET, cost: wager_size),
            round: 2,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::RAISE, cost: 2 * wager_size),
            round: 2,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::FOLD),
            round: 2,
            acting_player_position: 0
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 2,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 3,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::BET, cost: wager_size),
            round: 3,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 3,
            acting_player_position: 1
          }
        ]
        hands = x_game_def.number_of_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
"#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc/crc:#{hand_string}"

        MatchState.new(match_state).every_action(x_game_def) do |action, round, acting_player_position|
          x_yields = x_actions.shift

          action.must_equal x_yields[:action]
          round.must_equal x_yields[:round]
          acting_player_position.must_equal x_yields[:acting_player_position]
        end
      end
    end
  end
  describe '#players' do
    it 'return proper player states' do
      wager_size = 10
      x_game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*3,
        number_of_ranks: 3
      )
      x_actions = [
        [
          [
            PokerAction.new(PokerAction::RAISE, cost: wager_size + 10),
          ],
          [
            PokerAction.new(PokerAction::CHECK)
          ],
          [
            PokerAction.new(PokerAction::FOLD)
          ]
        ],
        [
          [
            PokerAction.new(PokerAction::CALL, cost: wager_size)
          ],
          [
            PokerAction.new(PokerAction::CHECK)
          ],
          [
            PokerAction.new(PokerAction::BET, cost: wager_size),
            PokerAction.new(PokerAction::CALL, cost: wager_size)
          ]
        ],
        [
          [
            PokerAction.new(PokerAction::CALL, cost: 5),
            PokerAction.new(PokerAction::CALL, cost: wager_size)
          ],
          [
            PokerAction.new(PokerAction::CHECK)
          ],
          [
            PokerAction.new(PokerAction::RAISE, cost: 2 * wager_size)
          ]
        ]
      ]
      x_contributions = x_actions.map_with_index do |actions_per_player, i|
        actions_per_player.map do |actions_per_round|
          actions_per_round.inject(0) { |sum, action| sum += action.cost }
        end.unshift(x_game_def.blinds[i])
      end
      x_winnings = [0, 0, x_contributions.flatten.inject(:+)]
      x_stacks = x_game_def.chip_stacks.map_with_index do |chip_stack, i|
        chip_stack - x_contributions[i].inject(:+) + x_winnings[i]
      end
      (0..x_game_def.number_of_players-1).each do |position|
        hands = x_game_def.number_of_players.times.map do |i|
          Hand.from_acpc "Ac#{i+2}h"
        end

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
          "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc:#{hand_string}"

        MatchState.new(
          match_state
        ).players(x_game_def).each_with_index do |player, pos|
          player.initial_stack.must_equal x_game_def.chip_stacks[pos]
          player.ante.must_equal x_game_def.blinds[pos]
          player.hand.must_equal hands[pos]
          player.actions.must_equal x_actions[pos]
          player.contributions.must_equal x_contributions[pos]
          player.winnings.must_equal x_winnings[pos]
          player.stack.must_equal x_stacks[pos]
        end
      end
    end
  end
  describe '#every_action' do
    it 'yields every action, plus the round number, and the acting player position relative to the dealer' do
      wager_size = 10
      x_game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*4,
        number_of_ranks: 3
      )

      (0..x_game_def.number_of_players-1).each do |position|
        x_actions = [
          {
            action: PokerAction.new(PokerAction::CALL, cost: 5),
            round: 0,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::RAISE, cost: wager_size + 10),
            round: 0,
            acting_player_position: 0
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 0,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 0,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 1,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 1,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 1,
            acting_player_position: 0
          },
          {
            action: PokerAction.new(PokerAction::BET, cost: wager_size),
            round: 2,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::RAISE, cost: 2 * wager_size),
            round: 2,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::FOLD),
            round: 2,
            acting_player_position: 0
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 2,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::CHECK),
            round: 3,
            acting_player_position: 1
          },
          {
            action: PokerAction.new(PokerAction::BET, cost: wager_size),
            round: 3,
            acting_player_position: 2
          },
          {
            action: PokerAction.new(PokerAction::CALL, cost: wager_size),
            round: 3,
            acting_player_position: 1
          }
        ]
        hands = x_game_def.number_of_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
      "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc/crc:#{hand_string}"

        MatchState.new(match_state).player_acting_sequence(x_game_def).must_equal(
          [[2, 0, 1, 2], [1, 2, 0], [1, 2, 0, 1], [1, 2, 1]]
        )
      end
    end
  end
  describe 'hand_ended?' do
    it 'works when there is a showdown' do
      wager_size = 10
      x_game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*4,
        number_of_ranks: 3
      )

      (0..x_game_def.number_of_players-1).each do |position|
        hands = x_game_def.number_of_players.times.map do |i|
          Hand.from_acpc "Ac#{i+2}h"
        end

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
          "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc/crc:#{hand_string}"

        MatchState.new(match_state).hand_ended?(x_game_def).must_equal true
      end
    end
    it 'works when there is not a showdown' do
      wager_size = 10
      x_game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*4,
        number_of_ranks: 3
      )

      (0..x_game_def.number_of_players-1).each do |position|
        hands = x_game_def.number_of_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
          "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrfc/cr:#{hand_string}"

        MatchState.new(match_state).hand_ended?(x_game_def).must_equal false
      end
    end
    it 'works when all other players have folded' do
      wager_size = 10
      x_game_def = GameDefinition.new(
        first_player_positions: [3, 2, 2, 2],
        chip_stacks: [100, 200, 150],
        blinds: [0, 10, 5],
        raise_sizes: [wager_size]*4,
        number_of_ranks: 3
      )

      (0..x_game_def.number_of_players-1).each do |position|
        hands = x_game_def.number_of_players.times.map { Hand.new }

        hands[position] = arbitrary_hole_card_hand

        hand_string = hands.inject('') do |hand_string, hand|
          hand_string << "#{hand}#{MatchState::HAND_SEPARATOR}"
        end[0..-2]

        match_state =
          "#{MatchState::LABEL}:#{position}:0:crcc/ccc/rrff:#{hand_string}"

        MatchState.new(match_state).hand_ended?(x_game_def).must_equal true
      end
    end
  end
  # @todo Test more chip distribution scenarios
end

def for_every_card
  Rank::DOMAIN.map do |rank, rank_properties|
    Suit::DOMAIN.map do |suit, suit_properties|
      yield Card.from_components(rank, suit)
    end
  end
end
def for_every_hand
  for_every_card do |first_card|
    for_every_card do |second_card|
      yield Hand.draw_cards(first_card, second_card)
    end
  end
end
def test_match_state_initialization_error(incomplete_match_state)
  ->{MatchState.parse incomplete_match_state}.must_raise(MatchState::IncompleteMatchState)
end
def test_match_state_success(match_state)
  patient = MatchState.parse match_state
  patient.to_s.must_equal match_state
  patient
end
def arbitrary_flop
  flop = ""
  rank = 2
  (Suit::DOMAIN.values.map { |suit| suit[:acpc_character] }).each do |suit|
    flop += rank.to_s + suit unless Suit::DOMAIN[:clubs][:acpc_character] == suit
    rank += 1
  end
  flop
end

def arbitrary_roll_out(rounds)
  community_cards = ""
  (1..rounds-1).each do |round|
    community_cards += "/" + if round > 1
      '2' + Suit::DOMAIN[:spades][:acpc_character]
    else
      arbitrary_flop
    end
  end

  community_cards
end

# Construct an arbitrary hole card hand.
#
# @return [Hand] An arbitrary hole card hand.
def arbitrary_hole_card_hand
  Hand.from_acpc(
    Rank::DOMAIN[:two][:acpc_character] +
    Suit::DOMAIN[:spades][:acpc_character] +
    Rank::DOMAIN[:three][:acpc_character] +
    Suit::DOMAIN[:hearts][:acpc_character]
  )
end