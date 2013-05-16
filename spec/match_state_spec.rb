
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'minitest/mock'
require 'acpc_dealer'

require "acpc_poker_types/match_state"
require "acpc_poker_types/poker_action"
require "acpc_poker_types/rank"
require "acpc_poker_types/suit"
require "acpc_poker_types/hand"
require "acpc_poker_types/card"
require 'acpc_poker_types/acpc_dealer_data/poker_match_data'

describe AcpcPokerTypes::MatchState do
  describe '#parse' do
    describe 'raises an exception if ' do
      describe 'the raw matchstate string' do
        it 'is empty' do
          test_match_state_initialization_error ""
        end

        it 'is not in the proper format' do
          test_match_state_initialization_error "hello world"
        end

        it 'does not contain a position' do
          test_match_state_initialization_error AcpcPokerTypes::MatchState::LABEL + "::0::AhKd"
        end

        it 'does not contain a hand number' do
          test_match_state_initialization_error AcpcPokerTypes::MatchState::LABEL + ":0:::AsKc"
        end

        it 'does not contain cards' do
          test_match_state_initialization_error AcpcPokerTypes::MatchState::LABEL + ":0:0::"
        end
      end
    end
    it "parses every possible limit action" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":1:1:"
      hole_cards = arbitrary_hole_card_hand
      AcpcPokerTypes::PokerAction::CANONICAL_ACTIONS.each do |action|
        match_state = partial_match_state + action + ":" + hole_cards.to_acpc
        patient = test_match_state_success match_state
        patient.last_action.to_s.must_equal action
      end
    end
    it "parses every possible hole card hand" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":2:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + hand.to_acpc + '|'

        test_match_state_success match_state
      end
    end
    it "parses opponent hole card hands in a two player game where the user is not the dealer" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":0:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + arbitrary_hole_card_hand.to_acpc + '|' + hand.to_acpc

        patient = test_match_state_success match_state

        (patient.list_of_opponents_hole_cards.map do |opponent_hand|
          opponent_hand.to_acpc
        end).must_equal [hand.to_acpc]
      end
    end
    it "parses opponent hole card hands in a two player game where the user is the dealer" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":1:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + hand.to_acpc + '|' + arbitrary_hole_card_hand.to_acpc

        patient = test_match_state_success match_state

        (patient.list_of_opponents_hole_cards.map do |opponent_hand|
           opponent_hand.to_acpc
        end).must_equal [hand.to_acpc]
      end
    end
    it 'parses board cards properly for the flop' do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc

      board_cards = '/AhKdQc'
      flop_match_state = partial_match_state + board_cards

      patient = AcpcPokerTypes::MatchState.parse flop_match_state

      patient.board_cards.to_acpc.must_equal board_cards
    end
    it 'parses board cards properly for the turn' do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc
      board_cards = '/AhKdQc/Jd'
      turn_match_state = partial_match_state + board_cards

      patient = AcpcPokerTypes::MatchState.parse turn_match_state

      patient.board_cards.to_acpc.must_equal board_cards
    end
    it 'parses board cards properly for the river' do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc
      board_cards = '/AhKdQc/Jd/Th'
      river_match_state = partial_match_state + board_cards

      patient = AcpcPokerTypes::MatchState.parse river_match_state

      patient.board_cards.to_acpc.must_equal board_cards
    end
    it "parses a valid two player final match state" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":20:22:"
      all_actions = AcpcPokerTypes::PokerAction::CANONICAL_ACTIONS.to_a.join ''
      betting = all_actions
      number_of_rounds = 100
      (number_of_rounds-1).times do
        betting += "/#{all_actions}"
      end
      board_cards = arbitrary_roll_out number_of_rounds
      hands = arbitrary_hole_card_hand.to_acpc + "|" + arbitrary_hole_card_hand.to_acpc

      match_state = partial_match_state + betting + ":" + hands + board_cards

      test_match_state_success match_state
    end
    it "parses a valid three player final match state" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":20:22:"
      all_actions = AcpcPokerTypes::PokerAction::CANONICAL_ACTIONS.to_a.join ''
      betting = all_actions
      number_of_rounds = 100
      (number_of_rounds-1).times do
        betting += "/#{all_actions}"
      end
      board_cards = arbitrary_roll_out number_of_rounds
      hands = arbitrary_hole_card_hand.to_s + "|" +
        arbitrary_hole_card_hand.to_s + "|" + arbitrary_hole_card_hand.to_s

      match_state = partial_match_state + betting + ":" + hands + board_cards

      test_match_state_success match_state
    end
  end

  describe '#round' do
    it "properly reports the current round number" do
      partial_match_state = AcpcPokerTypes::MatchState::LABEL + ":0:0:"
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
      match_state = AcpcPokerTypes::MatchState::LABEL + ':1:1::' + hands.join('|')

      patient = test_match_state_success match_state
      patient.number_of_players.must_equal expected_number_of_players
    end
  end

  describe '#last_action, #round_in_which_last_action_taken, and #first_state_of_first_round' do
    it 'returns +nil+ if no previous action exists, or true in the case of #first_state_of_first_round' do
      initial_match_state = "#{AcpcPokerTypes::MatchState::LABEL}:1:1::#{arbitrary_hole_card_hand}"
      patient = AcpcPokerTypes::MatchState.parse initial_match_state
      patient.last_action.must_be_nil
      patient.round_in_which_last_action_taken.must_be_nil
      patient.first_state_of_first_round?.must_equal true
    end
    it 'works properly if a previous action exists' do
      AcpcPokerTypes::PokerAction::CANONICAL_ACTIONS.each do |first_action|
        AcpcPokerTypes::PokerAction::CANONICAL_ACTIONS.each do |second_action|
          AcpcPokerTypes::PokerAction::CANONICAL_ACTIONS.each do |third_action|
            partial_match_state = "#{AcpcPokerTypes::MatchState::LABEL}:1:1:"

            partial_match_state += first_action
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = AcpcPokerTypes::MatchState.parse match_state
            patient.last_action.must_equal AcpcPokerTypes::PokerAction.new(first_action)
            patient.round_in_which_last_action_taken.must_equal 0
            patient.first_state_of_first_round?.must_equal false

            partial_match_state += "#{second_action}/"
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = AcpcPokerTypes::MatchState.parse match_state
            patient.last_action.must_equal AcpcPokerTypes::PokerAction.new(second_action)
            patient.round_in_which_last_action_taken.must_equal 0
            patient.first_state_of_first_round?.must_equal false

            partial_match_state += third_action
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = AcpcPokerTypes::MatchState.parse match_state
            patient.last_action.must_equal AcpcPokerTypes::PokerAction.new(third_action)
            patient.round_in_which_last_action_taken.must_equal 1
            patient.first_state_of_first_round?.must_equal false
          end
        end
      end
    end
  end
end
describe "#receive_matchstate_string" do
  it 'receives matchstate strings properly' do
    @connection = MiniTest::Mock.new
    match_logs.each do |log_description|
      match = AcpcPokerTypes::AcpcDealerData::PokerMatchData.parse_files(
        log_description.actions_file_path,
        log_description.results_file_path,
        log_description.player_names,
        AcpcDealer::DEALER_DIRECTORY,
        20
      )
      match.for_every_seat! do |seat|
        match.for_every_hand! do
          match.for_every_turn! do
            @connection.expect(:gets, match.current_hand.current_match_state.to_s)

            AcpcPokerTypes::MatchState.receive(@connection).must_equal match.current_hand.current_match_state
          end
        end
      end
    end
  end
end

def for_every_card
  AcpcPokerTypes::Rank::DOMAIN.map do |rank, rank_properties|
    AcpcPokerTypes::Suit::DOMAIN.map do |suit, suit_properties|
      yield AcpcPokerTypes::Card.from_components(rank, suit)
    end
  end
end
def for_every_hand
  for_every_card do |first_card|
    for_every_card do |second_card|
      yield AcpcPokerTypes::Hand.draw_cards(first_card, second_card)
    end
  end
end
def test_match_state_initialization_error(incomplete_match_state)
  ->{AcpcPokerTypes::MatchState.parse incomplete_match_state}.must_raise(AcpcPokerTypes::MatchState::IncompleteMatchState)
end
def test_match_state_success(match_state)
  patient = AcpcPokerTypes::MatchState.parse match_state
  patient.to_s.must_equal match_state
  patient
end
def arbitrary_flop
  flop = ""
  rank = 2
  (AcpcPokerTypes::Suit::DOMAIN.values.map { |suit| suit[:acpc_character] }).each do |suit|
    flop += rank.to_s + suit unless AcpcPokerTypes::Suit::DOMAIN[:clubs][:acpc_character] == suit
    rank += 1
  end
  flop
end

def arbitrary_roll_out(rounds)
  board_cards = ""
  (1..rounds-1).each do |round|
    board_cards += "/" + if round > 1
      '2' + AcpcPokerTypes::Suit::DOMAIN[:spades][:acpc_character]
    else
      arbitrary_flop
    end
  end

  board_cards
end

# Construct an arbitrary hole card hand.
#
# @return [AcpcPokerTypes::Hand] An arbitrary hole card hand.
def arbitrary_hole_card_hand
  AcpcPokerTypes::Hand.from_acpc(
    AcpcPokerTypes::Rank::DOMAIN[:two][:acpc_character] +
    AcpcPokerTypes::Suit::DOMAIN[:spades][:acpc_character] +
    AcpcPokerTypes::Rank::DOMAIN[:three][:acpc_character] +
    AcpcPokerTypes::Suit::DOMAIN[:hearts][:acpc_character]
  )
end