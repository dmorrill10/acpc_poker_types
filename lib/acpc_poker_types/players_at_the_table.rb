require 'acpc_poker_types/seat'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/player'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerTypes
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
end
using AcpcPokerTypes::MapWithIndex


module AcpcPokerTypes

class PlayersAtTheTable
  exceptions :player_acted_before_sitting_at_table,
    :no_players_to_seat, :multiple_players_have_the_same_seat

  attr_reader :players, :match_state, :game_def

  class << self; alias_method(:seat_players, :new) end

  # @param [GameDefinition] game_def The game definition for the
  #  match these players are playing
  # @param [#to_i] seat The user's seat. Defaults to zero.
  def initialize(game_def, seat = 0)
    @players = game_def.number_of_players.times.map do |i|
      Player.new(
        Seat.new(i, game_def.number_of_players)
      )
    end
    @game_def = game_def
    @seat = Seat.new(seat, game_def.number_of_players)
  end

  # @param [MatchState] match_state The next match state.
  def update!(match_state)
    @match_state = match_state

    update_players!
  end

  # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
  def hand_ended?
    return false unless @match_state

    @match_state.hand_ended? @game_def
  end

  # @return [Player] The player with the dealer button.
  def dealer_player
    return Player.new(nil) unless @match_state
    @players.find { |player| position_relative_to_dealer(player) == @players.length - 1}
  end
  def big_blind_payer
    @players.find do |plyr|
      position_relative_to_dealer(plyr) == @game_def.blinds.index(@game_def.blinds.max)
    end
  end
  def small_blind_payer
    @players.find do |plyr|
      position_relative_to_dealer(plyr) == (
        @game_def.blinds.index do |blind|
          blind < @game_def.blinds.max && blind > 0
        end
      )
    end
  end
  def next_player_to_act
    return Player.new(nil) if @match_state.nil? || hand_ended?

    @players.find { |plyr| position_relative_to_dealer(plyr) == @match_state.next_to_act(@game_def) }
  end

  # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
  def users_turn_to_act?
    return false if @match_state.nil? || hand_ended?

    next_player_to_act.seat == seat
  end

  # @param [Integer] player The player of which the position relative to the
  #  dealer is desired.
  # @return [Integer] The position relative to the dealer of the given player,
  #  +player+, indexed such that the player immediately to to the left of the
  #  dealer has a +position_relative_to_dealer+ of zero.
  # @raise (see Integer#seat_from_relative_position)
  # @raise (see Integer#position_relative_to)
  def position_relative_to_dealer(player)
    (seat.seats_to(player) + users_position_relative_to_dealer) % @players.length
  end

  # @return [Array] The set of legal actions for the currently acting player.
  def legal_actions
    return [] unless @match_state

    @match_state.legal_actions(@game_def)
  end

  # @return [String] player acting sequence as a string.
  def player_acting_sequence_string
    (player_acting_sequence.map { |per_round| per_round.join('') }).join('/')
  end

  # @return [Array<Array<Integer>>] The sequence of seats that acted,
  #  separated by round.
  def player_acting_sequence
    return [[]] unless @match_state

    @match_state.player_acting_sequence(@game_def).map do |actions_per_round|
      next [] if actions_per_round.empty?

      actions_per_round.map do |pos_rel_dealer|
        seat(pos_rel_dealer)
      end
    end
  end

  def seat(pos_rel_dealer = users_position_relative_to_dealer)
    return @seat if pos_rel_dealer == users_position_relative_to_dealer

    Seat.new(
      @seat + Seat.new(users_position_relative_to_dealer, @game_def.number_of_players).seats_to(pos_rel_dealer),
      @game_def.number_of_players
    )
  end

  def users_position_relative_to_dealer
    @match_state.position_relative_to_dealer
  end

  private

  def update_players!
    return self if @match_state.first_state_of_first_round?

    @players.each do |plyr|
      plyr.hand_player = @match_state.players(@game_def)[position_relative_to_dealer(plyr)]
    end

    distribute_chips! if hand_ended?

    self
  end

  # Distribute chips to all winning players
  # @param [BoardCards] board_cards The community board cards.
  def distribute_chips!
    @players.each do |plyr|
      plyr.balance += plyr.hand_player.balance
    end

    self
  end
end
end
