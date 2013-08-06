require 'celluloid/autostart'

require 'acpc_poker_types/dealer_data/action_messages'
require 'acpc_poker_types/dealer_data/hand_data'
require 'acpc_poker_types/dealer_data/hand_results'
require 'acpc_poker_types/dealer_data/match_definition'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerTypes
module DealerData

class PokerMatchData
  exceptions :match_definitions_do_not_match, :final_scores_do_not_match, :data_inconsistent, :names_do_not_match

  Player = Struct.new(:name, :seat, :balance)

  attr_accessor(
    # @returns [Array<Numeric>] Chip distribution at the end of the match
    :chip_distribution,
    # @returns [MatchDefinition] Game definition and match parameters
    :match_def,
    # @returns [Integer] Zero-index turn number within the hand
    :hand_number,
    # @returns [DealerData::HandData] Data from each hand
    :data,
    # @returns [Array<DealerData::PokerMatchData::Player>]
    :players,
    # @returns [Integer] Seat of the active player
    :seat
  )

  # @returns [DealerData::PokerMatchData]
  def self.parse_files(
    action_messages_file,
    result_messages_file,
    player_names,
    dealer_directory,
    num_hands=nil
  )
    parsed_action_messages = Celluloid::Future.new do
       DealerData::ActionMessages.parse_file(
        action_messages_file,
        player_names,
        dealer_directory,
        num_hands
      )
    end
    parsed_hand_results = Celluloid::Future.new do
       DealerData::HandResults.parse_file(
        result_messages_file,
        player_names,
        dealer_directory,
        num_hands
      )
    end

    new(
      parsed_action_messages.value,
      parsed_hand_results.value,
      player_names,
      dealer_directory
    )
  end

  # @returns [DealerData::PokerMatchData]
  def self.parse(
    action_messages,
    result_messages,
    player_names,
    dealer_directory,
    num_hands=nil
  )
    parsed_action_messages = Celluloid::Future.new do
       DealerData::ActionMessages.parse(
        action_messages,
        player_names,
        dealer_directory,
        num_hands
      )
    end
    parsed_hand_results = Celluloid::Future.new do
       DealerData::HandResults.parse(
        result_messages,
        player_names,
        dealer_directory,
        num_hands
      )
    end

    new(
      parsed_action_messages.value,
      parsed_hand_results.value,
      player_names,
      dealer_directory
    )
  end

  def initialize(
    parsed_action_messages,
    parsed_hand_results,
    player_names,
    dealer_directory
  )
    if (
      parsed_action_messages.match_def.nil? ||
      parsed_hand_results.match_def.nil? ||
      parsed_action_messages.match_def != parsed_hand_results.match_def
    )
      raise MatchDefinitionsDoNotMatch
    end

    if parsed_action_messages.final_score != parsed_hand_results.final_score
      raise FinalScoresDoNotMatch
    end

    @match_def = parsed_hand_results.match_def

    if parsed_hand_results.final_score
      set_chip_distribution! parsed_hand_results.final_score
    end

    set_data! parsed_action_messages, parsed_hand_results

    # Zero-indexed seat
    @seat = 0

    initialize_players!
  end

  def for_every_seat!
    match_def.game_def.number_of_players.times do |seat|
      @seat = seat

      initialize_players!

      yield seat
    end

    self
  end

  def player(seat=@seat) @players[seat] end

  def next_hand!
    init_or_increment_hand_num!
    current_hand.start_hand! @seat

    self
  end

  def end_hand!
    @players.each do |plyr|
      plyr.balance += hand_player(plyr).balance
    end
    current_hand.end_hand!

    self
  end

  def end_match!
    player_balances = @players.map { |plyr| plyr.balance }
    if @chip_distribution && @chip_distribution != player_balances
      raise DataInconsistent, "chip distribution: #{@chip_distribution}, player balances: #{player_balances}"
    end

    @hand_number = nil
    self
  end

  def hand_player_balances
    return [0] * match_def.game_def.number_of_players unless current_hand && current_hand.current_match_state

    @players.map { |p| hand_player(p).balance }
  end

  def hand_player(plyr = player)
    return nil unless current_hand && current_hand.current_match_state

    current_hand.current_match_state.players(match_def.game_def)[position_relative_to_dealer(plyr)]
  end

  def for_every_hand!
    while @hand_number.nil? || (@hand_number < @data.length - 1) do
      next_hand!
      yield @hand_number
      end_hand!
    end

    end_match!
  end

  def next_turn!
    current_hand.next_turn!

    @players.each_with_index do |player, seat|
      last_match_state = current_hand.last_match_state(seat)
      match_state = current_hand.current_match_state(seat)
    end

    self
  end

  def for_every_turn!
    while current_hand.turn_number.nil? || (current_hand.turn_number < current_hand.data.length - 1) do
      next_turn!
      yield current_hand.turn_number
    end

    self
  end

  def match_has_another_round?(current_round, turn_index, turns_taken)
    new_round?(current_round, turn_index) ||
    players_all_in?(current_round, turn_index, turns_taken)
  end

  def hand_started?
    @hand_number &&
    current_hand.turn_number &&
    current_hand.turn_number > 0
  end

  def player_acting_sequence
    sequence = [[]]

    return sequence unless hand_started?

    turns_taken = current_hand.data[0..current_hand.turn_number-1]
    turns_taken.each_with_index do |turn, turn_index|
      next unless turn.action_message

      sequence[turn.action_message.state.round] << turn.action_message.seat
      if match_has_another_round?(sequence.length - 1, turn_index, turns_taken)
        sequence << []
      end
    end

    sequence
  end

  def current_hand
    if @hand_number then @data[@hand_number] else nil end
  end

  def final_hand?
    if @hand_number then @hand_number >= @data.length - 1 else nil end
  end

  # return [Array<Integer>] Each player's current chip balance.
  def balances
    @players.map { |player| player.balance }
  end

  def opponents_cards_visible?
    return false unless current_hand

    current_hand.current_match_state.opponents_cards_visible?
  end
  def player_with_dealer_button
    return nil unless current_hand

    @players.find do |plr|
      position_relative_to_dealer(plr) == @players.length - 1
    end
  end

  def position_relative_to_dealer(plyr = player)
    return nil unless current_hand && current_hand.current_match_state(plyr.seat)

    current_hand.current_match_state(plyr.seat).position_relative_to_dealer
  end

  # @todo Untested
  # @return [String] player acting sequence as a string.
  def player_acting_sequence_string
    (player_acting_sequence.map { |per_round| per_round.join('') }).join('/')
  end
  def users_turn_to_act?
    return false unless current_hand && current_hand.next_action
    current_hand.next_action.seat == @seat
  end
  def betting_sequence
    sequence = [[]]

    if (
      @hand_number.nil? ||
      current_hand.turn_number.nil? ||
      current_hand.turn_number < 1
    )
      return sequence
    end

    turns_taken = current_hand.data[0..current_hand.turn_number-1]
    turns_taken.each_with_index do |turn, turn_index|
      next unless turn.action_message

      sequence[turn.action_message.state.round] << turn.action_message.action

      if (
        new_round?(sequence.length - 1 , turn_index) ||
        players_all_in?(sequence.length - 1, turn_index, turns_taken)
      )
        sequence << []
      end
    end

    sequence
  end
  def betting_sequence_string
    (betting_sequence.map do |per_round|
       (per_round.map{|action| action.to_acpc}).join('')
    end).join('/')
  end

  protected

  def initialize_players!
    @players = @match_def.player_names.length.times.map do |seat|
      Player.new(
        @match_def.player_names[seat],
        Seat.new(seat, @match_def.player_names.length),
        0
      )
    end
    self
  end

  def set_chip_distribution!(final_score)
    @chip_distribution = []
    final_score.each do |player_name, amount|
      begin
        @chip_distribution[@match_def.player_names.index(player_name.to_s)] = amount
      rescue TypeError => e
        raise NamesDoNotMatch.with_context(
          "Player name \"#{player_name.to_s}\" in match definition is not listed in final chip distribution",
          e
        )
      end
    end
    self
  end

  def set_data!(parsed_action_messages, parsed_hand_results)
    @data = []
    parsed_action_messages.data.zip(parsed_hand_results.data).each do |action_messages_by_hand, hand_result|
      @data << DealerData::HandData.new(
        @match_def,
        action_messages_by_hand,
        hand_result
      )
    end
    self
  end

  private

  def players_all_in?(current_round, turn_index, turns_taken)
    current_hand.data.length == turn_index + 2 &&
    current_round < (@match_def.game_def.number_of_rounds - 1) &&
    (turns_taken[0..turn_index].count do |t|
      t.action_message.action.to_acpc_character == PokerAction::FOLD
    end) != @players.length - 1
  end
  def new_round?(current_round, turn_index)
    current_hand.data.length > turn_index + 1 &&
    current_hand.data[turn_index + 1].action_message &&
    current_hand.data[turn_index + 1].action_message.state.round > current_round
  end
  def init_or_increment_hand_num!
    if @hand_number
      @hand_number += 1
    else
      @hand_number = 0
    end
    self
  end
end
end
end