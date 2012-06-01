
# Local mixins
require File.expand_path('../../mixins/utils', __FILE__)

# Local classes
require File.expand_path('../board_cards', __FILE__)
require File.expand_path('../chip_stack', __FILE__)

# A side-pot of chips.
class SidePot < ChipStack
   
   exceptions :illegal_operation_on_side_pot, :no_chips_to_distribute, :no_players_to_take_chips
   
   # @return [Hash<Player, Array<Integer>>] The set of players involved in this side-pot and the amounts they've contributed to this side-pot, organized according to round.
   attr_reader :players_involved_and_their_amounts_contributed
   
   # @return [Hash] The set of players involved in this side-pot and the amounts they've received from this side-pot.
   attr_reader :players_involved_and_their_amounts_received
   
   # @return [Integer] The current round.
   attr_accessor :round
   
   # @param [Player] initiating_player The player that initiated this side-pot.
   # @param [#to_i] initial_amount The initial value of this side-pot.
   # @raise (see ChipStack#initialize)
   def initialize(initiating_player, initial_amount)
      @round = 0
      initiating_player.take_from_chip_stack! initial_amount
      @players_involved_and_their_amounts_contributed = {initiating_player => [initial_amount]}
      @players_involved_and_their_amounts_received = {}
      
      super initial_amount.to_i
   end

   # @todo
   def contribute!(player, amount)
      player.take_from_chip_stack! amount
      unless @players_involved_and_their_amounts_contributed[player]
         @players_involved_and_their_amounts_contributed[player] = (1..@round).inject([]) { |array, i| array.push(0) }
      end
      
      set_current_amount_contributed player, amount
      
      # The value of the pot is equal to the sum of the amounts contributed by each player over each round
      @value = @players_involved_and_their_amounts_contributed.values.mapped_sum.sum
   end
   
   # Have the +calling_player+ call the bet in this side-pot.
   # @param [Player] calling_player The player calling the current bet in this side-pot.
   # @return [#to_i] The number of chips put in this side-pot.
   # @raise (see Player#take_from_chip_stack!)
   def take_call!(calling_player)      
      # @todo This only applies to not-Doyle's game no-limit and multiplayer
      # This method will raise an exception if the amount to call is larger than the player's stack so in the case that it is caught, the amount to call should be adjusted, and a new side-pot should be created.
      
      amount_for_this_player_to_call = amount_to_call calling_player
      calling_player.take_from_chip_stack! amount_for_this_player_to_call
      set_current_amount_contributed(calling_player, current_amount_contributed(calling_player) + amount_for_this_player_to_call)
      @value += amount_for_this_player_to_call.to_i
   end
   
   # @todo Create a set and get for current amount contributed and ensure that @round is always updated by the caller
   
   def amount_to_call(player)
      @players_involved_and_their_amounts_contributed[player] = [0] unless @players_involved_and_their_amounts_contributed[player]
      @players_involved_and_their_amounts_contributed[player].push(0) unless @players_involved_and_their_amounts_contributed[player].length > @round
      
      amount_contributed =  @players_involved_and_their_amounts_contributed[player].sum
      largest_amount_contributed = @players_involved_and_their_amounts_contributed.values.mapped_sum.max
      largest_amount_contributed - amount_contributed
   end
   
   # Have the +betting_player+ make a bet in this side-pot.
   # @param [Player] betting_player The player making a bet in this side-pot.
   # @param [#to_i] number_of_chips The number of chips to bet in this side-pot.
   # @raise (see Player#take_from_chip_stack!)
   def take_bet!(betting_player, number_of_chips)      
      betting_player.take_from_chip_stack! number_of_chips
      
      set_current_amount_contributed(betting_player, 0) unless current_amount_contributed(betting_player)
      set_current_amount_contributed(betting_player, current_amount_contributed(betting_player) + number_of_chips)
      
      @value += number_of_chips.to_i
   end
   
   # Have the +raising_player+ make a bet in this side-pot.
   # @param [Player] raising_player The player making a bet in this side-pot.
   # @param [Player] number_of_chips The number of chips to bet in this side-pot.
   # @raise (see #take_call!)
   # @raise (see #take_bet!)
   def take_raise!(raising_player, number_of_chips_to_raise_to)
      take_call! raising_player
      take_bet! raising_player, number_of_chips_to_raise_to - @players_involved_and_their_amounts_contributed[raising_player].sum
   end
   
   # Distribute chips to all winning players
   # @param [BoardCards] board_cards The community board cards.
   def distribute_chips!(board_cards)
      raise NoChipsToDistribute unless @value > 0
      
      players_to_distribute_to = list_of_players_who_have_not_folded
      
      raise NoPlayersToTakeChips unless players_to_distribute_to.length > 0
      
      if 1 == players_to_distribute_to.length
         winning_player = players_to_distribute_to[0]
         @players_involved_and_their_amounts_received[winning_player] = @value
         winning_player.take_winnings! @value
         
         @value = 0
      elsif
         distribute_winnings_amongst_multiple_players! players_to_distribute_to, board_cards
      end
      
      @players_involved_and_their_amounts_contributed = {}
   end
   
   private
   
   # return [Array] The list of players that have contributed to this side-pot who have not folded.
   def list_of_players_who_have_not_folded
      @players_involved_and_their_amounts_contributed.keys.reject { |player| player.has_folded }
   end
   
   def distribute_winnings_amongst_multiple_players!(list_of_players, board_cards)
      strength_of_the_strongest_hand = 0
      list_of_strongest_hands = []
      winning_players = []
      list_of_players.each do |player|
         hand_strength = PileOfCards.new(board_cards + player.hole_cards).to_poker_hand_strength
         if hand_strength >= strength_of_the_strongest_hand
            strength_of_the_strongest_hand = hand_strength
            if !list_of_strongest_hands.empty? && hand_strength > list_of_strongest_hands.max
               winning_players = [player]
               list_of_strongest_hands = [hand_strength]
            else
               winning_players << player
               list_of_strongest_hands << hand_strength
            end
         end
      end
      
      # Split the side-pot's value among the winners
      amount_each_player_wins = (@value/winning_players.length).floor
      winning_players.each do |player|
         @players_involved_and_their_amounts_received[player] = amount_each_player_wins
         player.take_winnings! amount_each_player_wins
      end
      
      # Remove chips from this side-pot
      @value -= (amount_each_player_wins * winning_players.length).to_i
   end
   
   def set_current_amount_contributed(player, amount)
      @players_involved_and_their_amounts_contributed[player][@round] = amount
   end
   
   def current_amount_contributed(player)
      @players_involved_and_their_amounts_contributed[player][@round]
   end
end
