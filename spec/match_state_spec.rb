
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require "#{LIB_ACPC_POKER_TYPES_PATH}/board_cards"
require "#{LIB_ACPC_POKER_TYPES_PATH}/match_state"
require "#{LIB_ACPC_POKER_TYPES_PATH}/poker_action"

describe MatchState do
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
          test_match_state_initialization_error MatchState::LABEL + "::0::AhKd"
        end

        it 'does not contain a hand number' do
          test_match_state_initialization_error MatchState::LABEL + ":0:::AsKc"
        end

        it 'does not contain cards' do
          test_match_state_initialization_error MatchState::LABEL + ":0:0::"
        end
      end
    end
    it "parses every possible limit action" do
      partial_match_state = MatchState::LABEL + ":1:1:"
      hole_cards = arbitrary_hole_card_hand
      PokerAction::LEGAL_ACPC_CHARACTERS.each do |action|
        match_state = partial_match_state + action + ":" + hole_cards.to_acpc
        patient = test_match_state_success match_state
        patient.last_action.to_acpc.should be == action
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

        (patient.list_of_opponents_hole_cards.map do |opponent_hand|
          opponent_hand.to_acpc
        end).should be == [hand.to_acpc]
      end
    end
    it "parses opponent hole card hands in a two player game where the user is the dealer" do
      partial_match_state = MatchState::LABEL + ":1:2::"
      for_every_hand do |hand|
        match_state = partial_match_state + hand.to_acpc + '|' + arbitrary_hole_card_hand.to_acpc

        patient = test_match_state_success match_state

        (patient.list_of_opponents_hole_cards.map do |opponent_hand|
           opponent_hand.to_acpc
        end).should be == [hand.to_acpc]
      end
    end
    it 'parses board cards properly for the flop' do
      partial_match_state = MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc

      board_cards = '/AhKdQc'
      flop_match_state = partial_match_state + board_cards

      patient = MatchState.parse flop_match_state

      patient.board_cards.to_acpc.should be == board_cards
    end
    it 'parses board cards properly for the turn' do
      partial_match_state = MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc
      board_cards = '/AhKdQc/Jd'
      turn_match_state = partial_match_state + board_cards

      patient = MatchState.parse turn_match_state

      patient.board_cards.to_acpc.should be == board_cards
    end
    it 'parses board cards properly for the river' do
      partial_match_state = MatchState::LABEL + ":2:2::" + arbitrary_hole_card_hand.to_acpc
      board_cards = '/AhKdQc/Jd/Th'
      river_match_state = partial_match_state + board_cards

      patient = MatchState.parse river_match_state

      patient.board_cards.to_acpc.should be == board_cards
    end
    it "parses valid limit match states in all rounds" do
      pending 'need to look at this test'

      test_all_rounds_with_given_action_string PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join ''
    end
    it "parses valid no-limit match states in all rounds" do
      pending 'need to look at this test'

      test_all_rounds_with_given_action_string PokerAction::LEGAL_ACTIONS[:raise], 1
    end
    it "parses a valid two player final match state" do
      partial_match_state = MatchState::LABEL + ":20:22:"
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join ''
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
      partial_match_state = MatchState::LABEL + ":20:22:"
      all_actions = PokerAction::LEGAL_ACPC_CHARACTERS.to_a.join ''
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
      partial_match_state = MatchState::LABEL + ":0:0:"
      betting = ""
      hand = arbitrary_hole_card_hand
      100.times do |i|
        match_state = partial_match_state + betting + ':|' + hand
        patient = test_match_state_success match_state
        patient.round.should be == i

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
      patient.number_of_players.should be == expected_number_of_players
    end
  end

  describe '#last_action, #round_in_which_last_action_taken, and #first_state_of_first_round' do
    it 'returns +nil+ if no previous action exists, or true in the case of #first_state_of_first_round' do
      initial_match_state = "#{MatchState::LABEL}:1:1::#{arbitrary_hole_card_hand}"
      patient = MatchState.parse initial_match_state
      patient.last_action.should == nil
      patient.round_in_which_last_action_taken.should == nil
      patient.first_state_of_first_round?.should == true
    end
    it 'works properly if a previous action exists' do
      PokerAction::LEGAL_ACPC_CHARACTERS.each do |first_action|
        PokerAction::LEGAL_ACPC_CHARACTERS.each do |second_action|
          PokerAction::LEGAL_ACPC_CHARACTERS.each do |third_action|
            partial_match_state = "#{MatchState::LABEL}:1:1:"

            partial_match_state += first_action
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = MatchState.parse match_state
            patient.last_action.should be == PokerAction.new(first_action)
            patient.round_in_which_last_action_taken.should == 0
            patient.first_state_of_first_round?.should == false

            partial_match_state += "#{second_action}/"
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = MatchState.parse match_state
            patient.last_action.should be == PokerAction.new(second_action)
            patient.round_in_which_last_action_taken.should == 0
            patient.first_state_of_first_round?.should == false

            partial_match_state += third_action
            match_state = "#{partial_match_state}:#{arbitrary_hole_card_hand}"

            patient = MatchState.parse match_state
            patient.last_action.should be == PokerAction.new(third_action)
            patient.round_in_which_last_action_taken.should == 1
            patient.first_state_of_first_round?.should == false
          end
        end
      end
    end
  end

  # @param [Integer] An amount to append to actions.  If none is given,
  #  +raise_amount+ defaults to an empty string.
  def test_all_rounds_with_given_action_string(action_string, raise_amount='')
    partial_match_state = MatchState::LABEL + ":1:0:"

    users_hole_cards = arbitrary_hole_card_hand
    list_of_opponents_hole_cards = [[]]

    (betting_string, list_of_betting_actions) = generate_betting_sequence action_string + raise_amount.to_s
    number_of_actions_this_round = list_of_betting_actions.length

    list_of_board_cards = []
    board_cards_string = ""

    number_of_rounds = 100
    (1..number_of_rounds-1).each do |round|
      match_state = partial_match_state + betting_string + ":|#{users_hole_cards}#{board_cards_string}"

      round_index = round - 1

      test_full_information(match_state, list_of_betting_actions,
                            last_action(list_of_betting_actions), users_hole_cards,
                            list_of_opponents_hole_cards, list_of_board_cards, round_index,
                            number_of_actions_this_round)

      # Make an interesting raise amount if the caller specified a raise amount in the first place
      raise_amount += 10**round + round*3 unless raise_amount.to_s.empty?

      betting_string = generate_betting_sequence(
        betting_string,
        list_of_betting_actions, 
        action_string + raise_amount.to_s
      )

      list_of_board_cards << (if round > 1 
        (round+1).to_s + Suit::DOMAIN[:spades][:acpc_character] 
      else 
        arbitrary_flop 
      end)
      board_cards_string += "/" + list_of_board_cards[round]
    end
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

  def generate_betting_sequence(betting_string = "", list_of_betting_actions = [], action_string)
    betting_string += if betting_string.empty?
      action_string
    else
      "/#{action_string}"
    end
    (list_of_betting_actions << action_string.scan(/[^\/]\d*/)).flatten!

    [betting_string, list_of_betting_actions]
  end

  def last_action(list_of_betting_actions)
    list_of_betting_actions[-1]
  end

  def test_full_information(match_state, list_of_betting_actions,
                            last_action, users_hole_cards, list_of_opponents_hole_cards,
                            list_of_board_cards, round, number_of_actions_this_round)

    patient = test_match_state_success match_state

    patient.betting_sequence.should be == list_of_betting_actions
    patient.last_action.should be == last_action
    patient.users_hole_cards.to_s.should be == users_hole_cards.to_s
    patient.list_of_opponents_hole_cards.should be == list_of_opponents_hole_cards
    (if patient.board_cards.join.empty? then [] else [patient.board_cards.join] end).should be == list_of_board_cards
    patient.round.should be == round
    patient.number_of_actions_this_round.should be == number_of_actions_this_round
  end

  def test_match_state_initialization_error(incomplete_match_state)
    expect{MatchState.parse incomplete_match_state}.to raise_exception(MatchState::IncompleteMatchState)
  end
  def test_match_state_success(match_state)
    patient = MatchState.parse match_state
    patient.to_s.should be == match_state

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
    board_cards = ""
    (1..rounds-1).each do |round|
      board_cards += "/" + if round > 1
        '2' + Suit::DOMAIN[:spades][:acpc_character]
      else
        arbitrary_flop
      end
    end

    board_cards
  end






  ##########
  # Initialization methods ---------------------------------------------------
  def create_initial_match_state(number_of_players=2)
    user_position = 1;
    hand_number = 0
    hole_card_hand = arbitrary_hole_card_hand
    initial_match_state = mock('MatchState')
    initial_match_state.stubs(:position_relative_to_dealer).returns(user_position)
    initial_match_state.stubs(:hand_number).returns(hand_number)
    initial_match_state.stubs(:list_of_board_cards).returns([])
    initial_match_state.stubs(:list_of_betting_actions).returns([])
    initial_match_state.stubs(:users_hole_cards).returns(hole_card_hand)
    initial_match_state.stubs(:list_of_opponents_hole_cards).returns([])
    initial_match_state.stubs(:list_of_hole_card_hands).returns(list_of_hole_card_hands(user_position, hole_card_hand, number_of_players))
    initial_match_state.stubs(:last_action).returns(nil)
    initial_match_state.stubs(:round).returns(0)
    initial_match_state.stubs(:number_of_actions_in_current_round).returns(0)

    raw_match_state =  MatchState::LABEL + ":#{user_position}:#{hand_number}::" + hole_card_hand
    initial_match_state.stubs(:to_s).returns(raw_match_state)

    [initial_match_state, user_position]
  end

  def list_of_hole_card_hands(user_position, user_hole_card_hand, number_of_players)
    number_of_entries_in_the_list = number_of_players - (if user_position == number_of_players - 1
      1
    else
      2
    end)

    number_of_entries_in_the_list.times.inject([]) do |i|
      hole_card_sets << (if i == user_position then user_hole_card_hand else '' end)
    end
  end

  def create_game_definition
    game_definition = mock('GameDefinition')
    game_definition.stubs(:number_of_players).returns(3)
    game_definition.stubs(:minimum_wager_in_each_round).returns([10, 10, 20, 20])
    game_definition.stubs(:first_player_position_in_each_round).returns([2, 1, 1, 1])
    game_definition.stubs(:max_raise_in_each_round).returns([3, 4, 4, 4])
    game_definition.stubs(:list_of_player_stacks).returns([20000, 20000, 20000])
    game_definition.stubs(:big_blind).returns(10)
    game_definition.stubs(:small_blind).returns(5)

    game_definition
  end

  def create_player_manager(game_definition)
    player_manager = mock('PlayerManager')

    (player_who_submitted_big_blind, player_who_submitted_small_blind, other_player) = create_players game_definition.big_blind, game_definition.small_blind

    player_manager.stubs(:player_who_submitted_big_blind).returns(player_who_submitted_big_blind)
    player_manager.stubs(:player_who_submitted_small_blind).returns(player_who_submitted_small_blind)
    player_manager.stubs(:players_who_did_not_submit_a_blind).returns([other_player])

    list_of_player_stacks = game_definition.list_of_player_stacks.dup
    player_manager.stubs(:list_of_player_stacks).returns(list_of_player_stacks)

    player_manager
  end

  def create_players(big_blind, small_blind)
    player_who_submitted_big_blind = mock('Player')
    player_who_submitted_big_blind.stubs(:current_wager_faced=).with(0)
    player_who_submitted_big_blind.stubs(:current_wager_faced).returns(0)
    player_who_submitted_big_blind.stubs(:name).returns('big_blind_player')

    player_who_submitted_small_blind = mock('Player')
    player_who_submitted_small_blind.stubs(:current_wager_faced=).with(big_blind - small_blind)
    player_who_submitted_small_blind.stubs(:current_wager_faced).returns(big_blind - small_blind)
    player_who_submitted_small_blind.stubs(:name).returns('small_blind_player')

    other_player = mock('Player')
    other_player.stubs(:current_wager_faced=).with(big_blind)
    other_player.stubs(:current_wager_faced).returns(big_blind)
    other_player.stubs(:name).returns('other_player')

    [player_who_submitted_big_blind, player_who_submitted_small_blind, other_player]
  end

  def setup_action_test(match_state, action_type, action_argument = '')
    action = action_argument + action_type
    expected_string = raw_match_state match_state, action

    expected_string
  end


  # Helper methods -----------------------------------------------------------

  def raw_match_state(match_state, action)
    "#{match_state}:#{action}"
  end

  # Construct an arbitrary hole card hand.
  #
  # @return [Mock Hand] An arbitrary hole card hand.
  def arbitrary_hole_card_hand
    Hand.from_acpc(
      Rank::DOMAIN[:two][:acpc_character] +
      Suit::DOMAIN[:spades][:acpc_character] +
      Rank::DOMAIN[:three][:acpc_character] +
      Suit::DOMAIN[:hearts][:acpc_character]
    )
  end
end
