require 'delegate'

require 'acpc_poker_types/chip_stack'
require 'acpc_poker_types/hand_player'
require 'acpc_poker_types/hand'

module AcpcPokerTypes

class NilHandPlayer < HandPlayer
  def initialize()
    @hand = Hand.new
    @initial_stack = 0
    @ante = 0
    @winnings = ChipStack.new 0
    @actions = [[]]
  end
  def stack() 0 end
  def contributions() [] end
  def total_contribution() 0 end
  def legal_actions(
    round: 0,
    amount_to_call: ChipStack.new(0),
    wager_illegal: false
  ) [] end
  def inactive?() false end
  def all_in?() false end
  def folded?() false end
end

class Player < DelegateClass(HandPlayer)
  attr_reader :seat, :hand_player
  attr_accessor :balance

  def initialize(seat)
    @seat = seat
    @balance = 0
    @hand_player = NilHandPlayer.new

    super @hand_player
  end

  def hand_player=(new_hand_player)
    @hand_player = new_hand_player

    __setobj__ @hand_player

    @hand_player
  end
end
end