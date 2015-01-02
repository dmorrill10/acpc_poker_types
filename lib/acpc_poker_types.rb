require "acpc_poker_types/version"

require "acpc_poker_types/board_cards"
require "acpc_poker_types/card"
require "acpc_poker_types/chip_stack"
require "acpc_poker_types/game_definition"
require "acpc_poker_types/hand"
require 'acpc_poker_types/hand_player_group'
require "acpc_poker_types/match_state"
require "acpc_poker_types/pile_of_cards"
require "acpc_poker_types/rank"
require "acpc_poker_types/suit"
require "acpc_poker_types/dealer_data"
require 'acpc_poker_types/seat'

module AcpcPokerTypes
  # @todo Functionality (but not implementation) duplicated
  # from AcpcPokerTypes::PlayersAtTheTable
  def dealer_index(hand_number, game_def)
    hand_number % game_def.number_of_players
  end
  def big_blind_payer_index(hand_number, game_def)
    (hand_number + game_def.blinds.index(game_def.blinds.max) - 1) % game_def.number_of_players
  end
  def small_blind_payer_index(hand_number, game_def)
    (hand_number + game_def.blinds.index(game_def.blinds.min) - 1) % game_def.number_of_players
  end

  def check_description(player)
    "#{player} checks"
  end
  def call_description(player, poker_action)
    "#{player} calls (#{poker_action.cost.to_i})"
  end
  def bet_description(player, poker_action)
    d = "#{player} bets"
    if poker_action.modifier
      d + " by #{poker_action.cost.to_i} to #{poker_action.modifier}"
    else
      d
    end
  end
  def limit_raise_description(
    player,
    poker_action,
    num_wagers_so_far,
    max_num_wagers
  )
    "#{player} calls and raises (##{num_wagers_so_far+1} of #{max_num_wagers})"
  end
  def no_limit_raise_description(player, poker_action, amount_to_call)
    "#{player} calls (#{amount_to_call}) and raises by #{poker_action.cost.to_i} to #{poker_action.modifier}"
  end
  def fold_description(player)
    "#{player} folds"
  end
  def hand_dealt_description(players, hand_number, game_def, number_of_hands)
    raise unless players.length == game_def.number_of_players
    big_blind_payer = players[big_blind_payer_index(
      hand_number,
      game_def
    )]
    small_blind_payer = players[small_blind_payer_index(
      hand_number,
      game_def
    )]
    dealer_player = players[dealer_index(
      hand_number,
      game_def
    )]
    "hand ##{hand_number} of #{number_of_hands} dealt by #{dealer_player}, #{small_blind_payer} pays SB (#{game_def.blinds.min}), #{big_blind_payer} pays BB (#{game_def.blinds.max})"
  end
  def hand_win_description(player, amount_won, current_balance)
    "#{player} wins #{amount_won}, bringing their balance to #{current_balance + amount_won}"
  end
  def split_pot_description(players, amount)
    a = if players.length > 2
      players[0..-2].join(', ') + ", and #{players.last}"
    else
      "#{players[0]} and #{players[1]}"
    end
    split_amount = (amount / players.length.to_r).round(2)
    "#{a} split the pot, each winning " + if split_amount == split_amount.to_i
        split_amount.to_i.to_s
      else
        sprintf("%0.2f", split_amount.to_f)
      end
  end
end