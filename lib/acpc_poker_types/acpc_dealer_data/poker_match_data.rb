
require 'acpc_poker_types/player'

require 'celluloid/autostart'

require 'dmorrill10-utils/class'

require 'acpc_poker_types/acpc_dealer_data/action_messages'
require 'acpc_poker_types/acpc_dealer_data/hand_data'
require 'acpc_poker_types/acpc_dealer_data/hand_results'
require 'acpc_poker_types/acpc_dealer_data/match_definition'

module AcpcPokerTypes::AcpcDealerData
  class PokerMatchData

    exceptions :match_definitions_do_not_match, :final_scores_do_not_match, :player_data_inconsistent

    attr_accessor(
      # @returns [Array<Numeric>] Chip distribution at the end of the match
      :chip_distribution,
      # @returns [MatchDefinition] Game definition and match parameters
      :match_def,
      # @returns [Integer] Zero-index turn number within the hand
      :hand_number,
      # @returns [ AcpcPokerTypes::AcpcDealerData::HandData] Data from each hand
      :data,
      # @returns [Array<AcpcPokerTypes::>] AcpcPokerTypes:: information
      :players,
      # @returns [Integer] Seat of the active player
      :seat
    )

    # @returns [ AcpcPokerTypes::AcpcDealerData::PokerMatchData]
    def self.parse_files(
      action_messages_file,
      result_messages_file,
      player_names,
      dealer_directory,
      num_hands=nil
    )
      parsed_action_messages = Celluloid::Future.new do
         AcpcPokerTypes::AcpcDealerData::ActionMessages.parse_file(
          action_messages_file,
          player_names,
          dealer_directory,
          num_hands
        )
      end
      parsed_hand_results = Celluloid::Future.new do
         AcpcPokerTypes::AcpcDealerData::HandResults.parse_file(
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

    # @returns [ AcpcPokerTypes::AcpcDealerData::PokerMatchData]
    def self.parse(
      action_messages,
      result_messages,
      player_names,
      dealer_directory,
      num_hands=nil
    )
      parsed_action_messages = Celluloid::Future.new do
         AcpcPokerTypes::AcpcDealerData::ActionMessages.parse(
          action_messages,
          player_names,
          dealer_directory,
          num_hands
        )
      end
      parsed_hand_results = Celluloid::Future.new do
         AcpcPokerTypes::AcpcDealerData::HandResults.parse(
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

      if (
        parsed_action_messages.final_score != parsed_hand_results.final_score
      )
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
      provide_players_with_new_hand!
      init_or_increment_hand_num!
      current_hand.start_hand! @seat
    end

    def end_match!
      if @chip_distribution && @chip_distribution != @players.map { |p| p.chip_balance }
        raise AcpcPokerTypes::DataInconsistent, "chip distribution: #{@chip_distribution}, player balances: #{@players.map { |p| p.chip_balance }}"
      end

      @hand_number = nil
      self
    end
# @todo Not working yet
    def for_every_hand!
      while @hand_number < @data.length do
        next_hand!
        yield @hand_number
        current_hand.end_hand!
      end

      end_match!
    end

    def next_turn!
      current_hand.next_turn!

      @players.each_with_index do |player, seat|
        last_match_state = current_hand.last_match_state(seat)
        match_state = current_hand.current_match_state(seat)

        if current_hand.last_action && player.seat == current_hand.last_action.seat

          player.take_action!(current_hand.last_action.action)
        end

        if (
          player.active? &&
          !match_state.first_state_of_first_round? &&
          match_state.round > last_match_state.round
        )
          player.start_new_round!
        end

        if current_hand.final_turn?
          player.take_winnings!(
            current_hand.chip_distribution[seat] + @match_def.game_def.blinds[current_hand.current_match_state(seat).position_relative_to_dealer]
          )
        end
      end
      self
    end

    def for_every_turn!
      current_hand.for_every_turn!(@seat) do |turn_number|
        next_turn!

        yield turn_number
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

    # @return [Array<ChipStack>] AcpcPokerTypes:: stacks.
    def chip_stacks
      @players.map { |player| player.chip_stack }
    end

    # return [Array<Integer>] Each player's current chip balance.
    def chip_balances
      @players.map { |player| player.chip_balance }
    end

    # return [Array<Array<Integer>>] Each player's current chip contribution organized by round.
    def chip_contributions
      @players.map { |player| player.chip_contributions }
    end

    def opponents
      @players.reject { |other_player| player == other_player }
    end
    def active_players
      @players.select { |player_to_collect| player_to_collect.active? }
    end
    def non_folded_players
      @players.reject { |player_to_reject| player_to_reject.folded? }
    end
    def opponents_cards_visible?
      return false unless current_hand

      current_hand.current_match_state.list_of_hole_card_hands.reject_empty_elements.length > 1
    end
    def player_with_dealer_button
      return nil unless current_hand

      @players.find do |plr|
        current_hand.current_match_state(plr.seat).position_relative_to_dealer == @players.length - 1
      end
    end
    # @return [Hash<AcpcPokerTypes::, #to_i] Relation from player to the blind that player paid.
    def player_blind_relation
      return nil unless current_hand

      @players.inject({}) do |relation, plr|
        relation[plr] = @match_def.game_def.blinds[current_hand.current_match_state(plr.seat).position_relative_to_dealer]
        relation
      end
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
    # @todo Test and implement this
    # def min_wager
    #   return nil unless current_hand

    #   @match_def.game_def.min_wagers[current_hand.next_state.round]
    #   ChipStack.new [@min_wager.to_i, action_with_context.cost.to_i].max
    # end

    protected

    def initialize_players!
      @players = @match_def.player_names.length.times.map do |seat|
        AcpcPokerTypes::Player.join_match(
          @match_def.player_names[seat],
          seat,
          @match_def.game_def.chip_stacks[seat]
        )
      end
      self
    end

    def set_chip_distribution!(final_score)
      @chip_distribution = []
      final_score.each do |player_name, amount|
        begin
          @chip_distribution[@match_def.player_names.index(player_name.to_s)] = amount
        rescue TypeError
          raise AcpcPokerTypes::NamesDoNotMatch
        end
      end
      self
    end

    def set_data!(parsed_action_messages, parsed_hand_results)
      @data = []
      parsed_action_messages.data.zip(parsed_hand_results.data).each do |action_messages_by_hand, hand_result|
        @data <<  AcpcPokerTypes::AcpcDealerData::HandData.new(
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
        t.action_message.action.to_acpc_character == AcpcPokerTypes::PokerAction::FOLD
      end) != @players.length - 1
    end
    def new_round?(current_round, turn_index)
      current_hand.data.length > turn_index + 1 &&
      current_hand.data[turn_index + 1].action_message &&
      current_hand.data[turn_index + 1].action_message.state.round > current_round
    end
    def provide_players_with_new_hand!
      @players.each_with_index do |player, seat|
        player.start_new_hand!(
          @match_def.game_def.blinds[current_hand.data.first.state_messages[seat].position_relative_to_dealer],
          @match_def.game_def.chip_stacks[current_hand.data.first.state_messages[seat].position_relative_to_dealer],
          current_hand.data.first.state_messages[seat].users_hole_cards
        )
      end
      self
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