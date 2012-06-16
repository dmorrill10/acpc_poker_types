
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/player", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/poker_action", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/hand", __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/match_state_string", __FILE__)

# Local modules
require File.expand_path('../../support/dealer_data', __FILE__)

describe Player do
   include DealerData
   
   NAME = 'p1'
   SEAT = '1'
   INITIAL_CHIP_STACK = 100000
   BLIND = 100
   
   before(:each) do
      init_before_first_turn_data!

      init_patient!
   end
   
   describe '::create_players' do
      it "raises an exception if the number of player names doesn't match the number of players from the game definition" do
         game_def = mock 'GameDefinition'
         various_numbers_of_players do |number_of_players|
            game_def.stubs(:number_of_players).returns(number_of_players)
            
            expect do
               Player.create_players(
                  ((number_of_players-1).times.inject([]) do |names, i|
                       names << "p#{i}"
                    end
                  ),
                  game_def
               )
            end.to raise_exception(Player::IncorrectNumberOfPlayerNames)
            expect do
               Player.create_players(
                  ((number_of_players+1).times.inject([]) do |names, i|
                       names << "p#{i}"
                    end
                  ),
                  game_def
               )
            end.to raise_exception(Player::IncorrectNumberOfPlayerNames)
         end
      end
      it 'works properly' do
         game_def = mock 'GameDefinition'
         various_numbers_of_players do |number_of_players|
            game_def.stubs(:number_of_players).returns(number_of_players)
            game_def.expects(:chip_stacks).times(number_of_players).returns(INITIAL_CHIP_STACK)
         
            patients = Player.create_players(
               (number_of_players.times.inject([]) do |names, i|
                  names << "p#{i}"
               end),
               game_def
            )
            
            patients.length.should == number_of_players
            patients.each do |patient|
               patient.class.should == Player
            end
         end
      end
   end
   describe '#join_match' do
      it 'initializes properly' do         
         check_patient
      end
   end
   describe '#take_action!' do
      describe 'updates player state properly' do
         it 'given the player did not fold' do
            test_sequence_of_non_fold_actions
         end
      end
   end
   describe '#start_new_hand!' do
      describe 'resets player data properly after taking actions' do
         it "in Doyle's game" do
            i = 0
            various_hands do |hand|
               init_patient!
               @position_relative_to_dealer = i
               
               test_sequence_of_non_fold_actions hand
               
               i += 1
            end
         end
         it 'in a continuous game' do
            i = 0
            various_hands do |hand|
               init_patient!
               @position_relative_to_dealer = i
               
               test_sequence_of_non_fold_actions hand
               
               i += 1
            end
         end
      end
   end
   describe 'reports it is not active if' do
      it 'it has folded' do   
         action = PokerAction.new :fold, {amount_to_put_in_pot: 0}
         
         @patient.start_new_hand! BLIND, INITIAL_CHIP_STACK
         @patient.take_action! action
         
         @chip_stack = INITIAL_CHIP_STACK - BLIND
         @chip_balance = -BLIND
         @chip_contributions = [BLIND]
         @hole_cards = Hand.new
         @actions_taken_this_hand = [[action]]
         @has_folded = true
         @is_all_in = false
         @is_active = false
         @round = 0

         check_patient
      end
      it 'it is all-in' do
         action = PokerAction.new :raise, {amount_to_put_in_pot: INITIAL_CHIP_STACK - BLIND}
         
         hand = default_hand
         @patient.start_new_hand! BLIND, INITIAL_CHIP_STACK, hand
         @patient.take_action! action
         
         @chip_stack = 0
         @chip_balance = -INITIAL_CHIP_STACK
         @chip_contributions = [INITIAL_CHIP_STACK]
         @hole_cards = hand
         @actions_taken_this_hand = [[action]]
         @has_folded = false
         @is_all_in = true
         @is_active = false
         @round = 0
         
         check_patient
      end
   end
   it 'properly changes its state when it wins chips' do
      @patient.chip_balance.should be == 0
      
      pot_size = 22
      @patient.take_winnings! pot_size
      
      @patient.chip_stack.should be == INITIAL_CHIP_STACK + pot_size
      @patient.chip_balance.should be == pot_size
      @patient.chip_contributions.should be == [0, -pot_size]
   end
   it 'works properly over samples of data from the ACPC Dealer' do
      DealerData::DATA.each do |num_players, data_by_num_players|
         ((0..(num_players-1)).map{ |i| (i+1).to_s }).each do |seat|
            data_by_num_players.each do |type, data_by_type|
               @hand_num = 0
               @seat = seat.to_i - 1
               turns = data_by_type[:actions]
               
               init_before_first_turn_data!

               init_patient!
               
               check_patient

               @actions_taken_this_hand = [[]]

               max_turns = 1000
               turns.each_index do |i|
                  break if i == max_turns
                  turn = turns[i]
                  next_turn = turns[i + 1]
                  from_player_message = turn[:from_players]
                  match_state_string = turn[:to_players][seat]
                  prev_round = if @match_state then @match_state.round else nil end
                  @match_state = MatchStateString.parse match_state_string
                  @round = @match_state.round
                  @has_folded = false

                  @hole_card_hands = order_by_seat_from_dealer_relative @match_state.list_of_hole_card_hands,
                     @seat, @match_state.position_relative_to_dealer
                  @hole_cards = @hole_card_hands[@seat]

                  @blinds = order_by_seat_from_dealer_relative(
                     DealerData::GAME_DEFS[type][:blinds],
                     @seat, 
                     @match_state.position_relative_to_dealer
                  )
                  
                  if @match_state.first_state_of_first_round?
                     init_new_hand_data! type

                     @patient.start_new_hand!(
                        @blinds[@seat], 
                        @chip_stack + @chip_contributions.first,
                        @hole_cards
                     ).should be @patient
                  else
                     init_new_turn_data! type, from_player_message, prev_round
                  end
                  
                  if !next_turn || MatchStateString.parse(next_turn[:to_players]['1']).first_state_of_first_round?
                     @chip_balance += @chip_contributions.sum
                     @chip_stack += @chip_contributions.sum

                     @patient.take_winnings!(@chip_contributions.sum).should be @patient

                     @chip_contributions << -@chip_contributions.sum
                  end

                  @is_all_in = @chip_stack <= 0
                  @is_active = !(@has_folded || @is_all_in)
                  
                  check_patient
               end
            end
         end
      end
   end
   
   def various_numbers_of_players
      (1..100).each do |number_of_players|
         yield number_of_players
      end
   end
   def check_patient
      @patient.name.should == @name
      @patient.seat.should == @seat
      @patient.chip_stack.should == @chip_stack
      @patient.chip_contributions.should == @chip_contributions
      @patient.chip_balance.should == @chip_balance
      if @hole_cards
         (@patient.hole_cards.map { |card| card.to_s} ).should == @hole_cards.map { |card| card.to_s }
      else
         @patient.hole_cards.should be nil
      end
      @patient.actions_taken_this_hand.should == @actions_taken_this_hand
      @patient.folded?.should == @has_folded
      @patient.all_in?.should == @is_all_in
      @patient.active?.should == @is_active
      @patient.round.should == @round
      @patient.chip_contributions_over_hand.should == @chip_contributions.sum
      @patient.chip_balance_over_hand.should == -@chip_contributions.sum
   end
   def various_actions
      various_amounts_to_put_in_pot do |amount|
         with_and_without_a_modifier do |modifier|
            instantiate_each_action_from_symbols(amount, modifier) do |action|
               yield action
            end
         end
      end
   end
   def default_modifier
      modifier_amount = 9001
      modifier = mock 'ChipStack'
      modifier.stubs(:to_s).returns(modifier_amount.to_s)
      modifier
   end
   def various_amounts_to_put_in_pot
      [0, 9002, -9002].each do |amount|
         yield amount
      end
   end
   def with_and_without_a_modifier
      [nil, default_modifier].each do |modifier|
         yield modifier
      end
   end
   def instantiate_each_action_from_symbols(amount_to_put_in_pot=0,
                                            modifier=nil)
      PokerAction::LEGAL_SYMBOLS.each do |sym|
         modifier = if PokerAction::MODIFIABLE_ACTIONS.keys.include? sym
            modifier
         else
            nil
         end
         
         action = mock 'PokerAction'
         action.stubs(:to_sym).returns(sym)
         action.stubs(:to_s).returns(sym.to_s + modifier.to_s)
         action.stubs(:to_acpc).returns(PokerAction::LEGAL_ACTIONS[sym] + modifier.to_s)
         action.stubs(:to_acpc_character).returns(PokerAction::LEGAL_ACTIONS[sym])
         action.stubs(:amount_to_put_in_pot).returns(amount_to_put_in_pot)
         action.stubs(:modifier).returns(modifier)
         
         yield action
      end
   end
   def test_sequence_of_non_fold_actions(hole_cards=default_hand)
      @hole_cards = hole_cards
      @has_folded = false

      @patient.start_new_hand! BLIND, INITIAL_CHIP_STACK, @hole_cards

      init_new_hand_data!

      number_of_rounds = 4
      number_of_rounds.times do |round|
         @round = round

         unless 0 == round
            @patient.start_new_round! 
            @chip_contributions << 0
            @actions_taken_this_hand << []
         end
         
         various_actions do |action|
            next if :fold == action.to_sym
            
            chip_stack_adjustment = if @chip_stack - action.amount_to_put_in_pot >= 0
               action.amount_to_put_in_pot
            else @chip_stack end
            
            @chip_balance -= chip_stack_adjustment
            @chip_stack -= chip_stack_adjustment
            @chip_contributions[-1] += chip_stack_adjustment
            
            @is_all_in = 0 == @chip_stack
            @is_active = !@is_all_in
            
            @actions_taken_this_hand.last << action
            
            @patient.take_action! action
            
            check_patient
         end
      end
   end
   def various_hands
      ([default_hand] * 10).each do |hole_cards|
         yield hole_cards
      end
   end
   def default_hand
      hidden_cards = Hand.new
      
      hidden_cards
   end
   def init_patient!
      @patient = Player.join_match @name, @seat, @chip_stack
   end
   def init_before_first_turn_data!
      @name = NAME
      @seat = SEAT.to_i - 1
      @chip_stack = INITIAL_CHIP_STACK
      @chip_balance = 0

      @hole_cards = nil
      @actions_taken_this_hand = [[]]
      @has_folded = false
      @is_all_in = false
      @is_active = true
      @round = 0
      @chip_contributions = [0]
   end
      def init_new_hand_data!(type=nil)
      @actions_taken_this_hand = [[]]
      init_new_hand_chip_data! type
   end
   def init_new_hand_chip_data!(type=nil)
      # @todo Assumes Doyle's Game
      @chip_contributions = [if type then @blinds[@seat] else BLIND end]
      @chip_balance = -@chip_contributions.first
      @chip_stack = (if type then DealerData::GAME_DEFS[type][:stack_size] else INITIAL_CHIP_STACK end) - @chip_contributions.first
   end
   def init_new_turn_data!(type, from_player_message, prev_round)
      seat_taking_action = from_player_message.keys.first
      seat_of_last_player_to_act = seat_taking_action.to_i - 1
      
      @last_action = PokerAction.new(
         from_player_message[seat_taking_action], 
         {
            amount_to_put_in_pot: DealerData::GAME_DEFS[type][:small_bets][@match_state.round],
         }
      )

      if seat_of_last_player_to_act == @seat
         @actions_taken_this_hand.last << @last_action

         @chip_contributions[-1] += @last_action.amount_to_put_in_pot.to_i
         @chip_stack -= @last_action.amount_to_put_in_pot
         @chip_balance -= @last_action.amount_to_put_in_pot.to_i

         @patient.take_action!(@last_action).should be @patient

         if from_player_message[seat_taking_action] == 'f'
            @has_folded = true
         end
      end
      if @match_state.round != prev_round
         @actions_taken_this_hand << []

         @chip_contributions << 0
         
         @patient.start_new_round!.should be @patient
      end
   end
end