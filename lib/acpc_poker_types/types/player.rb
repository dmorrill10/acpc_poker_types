
# Local classes
require File.expand_path('../chip_stack', __FILE__)
require File.expand_path('../game_definition', __FILE__)

# Local mixins
require File.expand_path('../../mixins/utils', __FILE__)

# Class to model a player.
class Player
   exceptions :incorrect_number_of_player_names
   
   def self.create_players(player_names, game_def)
      if game_def.number_of_players != player_names.length
         raise(
            IncorrectNumberOfPlayerNames,
            "#{player_names.length} names for #{game_def.number_of_players} players"
         )
      end
      
      game_def.number_of_players.times.inject([]) do |players, seat|
         players << Player.join_match(player_names[seat],
                                      seat,
                                      ChipStack.new(game_def.chip_stacks[seat])
                                      )
      end
   end
   
   # @return [String] The name of this player.
   attr_reader :name
   
   # @return [Integer] This player's seat.  This is a 0 indexed
   #  number that represents the order that this player joined the dealer.
   attr_reader :seat

   # @return [ChipStack] This player's chip stack.
   attr_reader :chip_stack
   
   # @return [Array<ChipStack>] This player's contribution to the pot in the
   #  current hand, organized by round.
   attr_reader :chip_contributions
   
   # @return [Integer] The amount this player has won or lost in the current
   #  match.  During a hand, this is a projected amount assuming that this
   #  player loses.  Positive amounts are winnings, negative amounts are losses.
   attr_reader :chip_balance
   
   # @return [Hand] This player's hole cards or nil if this player is not
   #  holding cards.
   # @example (see MatchStateString#users_hole_cards)
   attr_reader :hole_cards
   
   # @return [Array<Array<PokerAction>>] The list of actions this player has taken in
   #  the current hand, separated by round.
   attr_reader :actions_taken_this_hand
   
   alias_new :join_match
   
   # @todo These comments don't work as expected
   # @param [String] name This players name.
   # @param [Integer] seat (see #seat)
   # @param [#to_i] chip_stack (see #chip_stack)
   def initialize(name, seat, chip_stack)
      @name = name
      @seat = seat
      @chip_balance = 0
      @chip_stack = chip_stack
      @chip_contributions = [0]
      
      @actions_taken_this_hand = [[]]
   end

   def to_s
      @name.to_s
   end
	
	# @param [#to_i] blind_amount The blind amount for this player to pay.
	# @param [#to_i] chip_stack (see #chip_stack)
	# @param [Hand] hole_cards (see #hole_cards)
	def start_new_hand!(blind=ChipStack.new(0), chip_stack=@chip_stack, hole_cards=Hand.new)
      @chip_stack = chip_stack
      @hole_cards = hole_cards
      @actions_taken_this_hand = []
      @chip_contributions = []
      
      start_new_round!

      pay_blind! blind
	end
	
	def start_new_round!
      @actions_taken_this_hand << []
      @chip_contributions << 0

      self
	end
	
	# @param [PokerAction] action The action to take.
	def take_action!(action)
      @actions_taken_this_hand.last << action
      
      take_from_chip_stack! action.amount_to_put_in_pot
	end
	
	# @return [Boolean] Reports whether or not this player has folded.
	def folded?
      if @actions_taken_this_hand.last.empty?
         false
      else
         :fold == @actions_taken_this_hand.last.last.to_sym
      end
	end
	
	# @return [Boolean] Reports whether or not this player is all-in.
	def all_in?
      0 == @chip_stack
	end
   
   # @return [Boolean] Whether or not this player is active (has not folded
   #     or gone all-in). +true+ if this player is active, +false+ otherwise.
   def active?
      !(folded? || all_in?)
   end
   
   # @return [Integer] The current round, zero indexed.
   def round
      @actions_taken_this_hand.length - 1
   end
      
   # Adjusts this player's state when it takes chips from the pot.
   # @param [Integer] chips The number of chips this player has won from the pot.
   def take_winnings!(chips)
      @chip_contributions << 0

      add_to_stack! chips
   end
   
   def assign_cards!(hole_cards)
      @hole_cards = hole_cards

      self
   end
   
   def chip_contributions_over_hand
      @chip_contributions.sum
   end
   
   def chip_balance_over_hand
      -chip_contributions_over_hand
   end
   
   private
   
   # @param [#to_i] blind_amount The blind amount for this player to pay.
   def pay_blind!(blind_amount)
      take_from_chip_stack! blind_amount
   end
   
   def add_to_stack!(chips)
      @chip_stack += chips
      @chip_balance += chips.to_i
      @chip_contributions[-1] -= chips.to_i

      self
   end
   
   # Take chips away from this player's chip stack.
   # @param (see ChipStack#-)
   # @raise (see ChipStack#-)
   def take_from_chip_stack!(number_of_chips)
      @chip_stack -= number_of_chips
      @chip_balance -= number_of_chips.to_i
      @chip_contributions[-1] += number_of_chips.to_i

      self
   end
end
