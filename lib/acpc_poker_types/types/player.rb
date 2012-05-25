
# Local classes
require File.expand_path('../chip_stack', __FILE__)

# Local mixins
require File.expand_path('../../mixins/utils', __FILE__)

# Class to model a player.
class Player
   include Comparable
   
   # @return [String] The name of this player.
   attr_reader :name
   
   # @return [Integer] This player's seat.  This is a 0 indexed
   #  number that represents the order that this player joined the dealer.
   attr_reader :seat

   # @return [ChipStack] This player's chip stack.
   attr_reader :chip_stack
   
   # @return [Array<ChipStack>] This player's contribution to the pot in the
   #  current hand, organized by round.
   attr_reader :chip_contribution
   
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
   # @param [String] name (see #name)
   # @param [Integer] seat (see #seat)
   # @param [#to_i] chip_stack (see #chip_stack)
   def initialize(name, seat, chip_stack)
      @name = name
      @seat = seat
      @chip_balance = 0
      @chip_stack = chip_stack
      @chip_contribution = [0]
      
      @actions_taken_this_hand = [[]]
   end
   
   # @return [String] String representation of this player.
   def to_s
      to_hash.to_s
   end
   
	# @return [Hash] Hash map representation of this player.
	def to_hash
      hash_rep = {}
		self.instance_variables.each { |var| hash_rep.store(var.to_s.delete("@"), self.instance_variable_get(var)) }
		hash_rep["chip_stack"] = @chip_stack.to_i
		hash_rep["hole_cards"] = @hole_cards.to_s
		hash_rep['actions_taken_this_hand'] = actions_taken_this_hand_to_string
		
		hash_rep
	end
	
	def actions_taken_this_hand_to_string
      return '' unless @actions_taken_this_hand
      (@actions_taken_this_hand.map do |actions_per_round|
         (actions_per_round.map { |action| action.to_acpc }).join('')
      end).join('/')
	end
	
	# @param [#to_i] blind_amount The blind amount for this player to pay.
	# @param [#to_i] chip_stack (see #chip_stack)
	# @param [Hand] hole_cards (see #hole_cards)
	def start_new_hand!(blind=ChipStack.new(0), chip_stack=@chip_stack, hole_cards=Hand.new)
      @chip_stack = chip_stack
      @hole_cards = hole_cards
      @actions_taken_this_hand = []
      @chip_contribution = []
      
      start_new_round!
      
      pay_blind!(blind)
	end
	
	def start_new_round!
      @actions_taken_this_hand << []
      @chip_contribution << 0
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
   # @param [Integer] number_of_chips_from_the_pot The number of chips
   #  this player has won from the pot.
   # @raise (see #take_from_chip_stack!)
   def take_winnings!(number_of_chips_from_the_pot)
      add_to_stack number_of_chips_from_the_pot
   end
   
   def assign_cards!(hole_cards)
      @hole_cards = hole_cards
   end
   
   def chip_contribution_over_hand
      @chip_contribution.inject(0) { |sum, per_round| sum += per_round }
   end
   
   def chip_balance_over_hand
      -chip_contribution_over_hand
   end
   
   private
   
   # @param [#to_i] blind_amount The blind amount for this player to pay.
   def pay_blind!(blind_amount)
      take_from_chip_stack! blind_amount
   end
   
   def add_to_stack(chips)
      @chip_stack += chips
      @chip_balance += chips.to_i
      @chip_contribution[-1] -= chips.to_i
   end
   
   # Take chips away from this player's chip stack.
   # @param (see ChipStack#-)
   # @raise (see ChipStack#-)
   def take_from_chip_stack!(number_of_chips)
      @chip_stack -= number_of_chips
      @chip_balance -= number_of_chips.to_i
      @chip_contribution[-1] += number_of_chips.to_i
   end
end
