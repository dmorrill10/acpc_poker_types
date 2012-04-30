
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../../support/spec_helper', __FILE__)

# Local classes
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/types/side_pot", __FILE__)

# Local modules
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/acpc_poker_types_defs", __FILE__)

describe SidePot do
   include AcpcPokerTypesDefs
   
   before do
      @player1 = mock 'Player'
      @player2 = mock 'Player'
   end
   
   describe 'knows the players who have added to its value' do
      it 'when it is first created' do
         setup_succeeding_test
      end
      it 'when a player makes a bet' do
         setup_succeeding_test
         calling_test
         betting_test
      end
      it 'when a player calls the current bet' do
         setup_succeeding_test
         calling_test
      end
      it 'when a player raises the current bet' do
         setup_succeeding_test
         calling_test
         betting_test
         raising_test
      end
   end
   
   describe 'keeps track of the amount that has been added to its value' do
      it 'when it is first created' do
         setup_succeeding_test
         
         @patient.should be == @initial_amount_in_side_pot
      end
      it 'when a player makes a bet' do
         setup_succeeding_test
         calling_test
         betting_test

         @patient.should be == 2 * @initial_amount_in_side_pot + @amount_to_bet
      end
      it 'when a player calls the current bet' do
         setup_succeeding_test
         calling_test
         
         @patient.should be == 2 * @initial_amount_in_side_pot
      end
      it 'when a player raises the current bet' do
         setup_succeeding_test
         calling_test
         betting_test
         raising_test
         
         @patient.should be == @initial_amount_in_side_pot + @amount_to_bet + @amount_to_raise_to
      end
   end
   
   it 'keeps track of player contributions over each round' do
      play_through_all_rounds
      distributes_chips_properly_when_one_player_left @players_and_their_contributions.values.mapped_sum.sum
      
      play_through_all_rounds
      distributes_chips_properly_when_two_players_left_equal_strength @players_and_their_contributions.values.mapped_sum.sum
      
      play_through_all_rounds
      distributes_chips_properly_when_two_players_left_unequal_strength @players_and_their_contributions.values.mapped_sum.sum
   end
   
   describe '#distribute_chips!' do
      it 'distributes chips properly when only one player involved has not folded' do
         setup_succeeding_test
         calling_test
         betting_test
         
         chips_to_distribute = 2 * @initial_amount_in_side_pot + @amount_to_bet
         
         distributes_chips_properly_when_one_player_left chips_to_distribute
      end
      it 'distributes the chips it contains properly to two players that have not folded and have equal hand strength' do
         setup_succeeding_test
         calling_test
         betting_test
         
         chips_to_distribute = 2 * @initial_amount_in_side_pot + @amount_to_bet
         
         distributes_chips_properly_when_two_players_left_equal_strength chips_to_distribute
      end
      it 'distributes the chips it contains properly to two players that have not folded and have unequal hand strength' do
         setup_succeeding_test
         calling_test
         betting_test
         
         chips_to_distribute = 2 * @initial_amount_in_side_pot + @amount_to_bet
         
         distributes_chips_properly_when_two_players_left_unequal_strength chips_to_distribute
      end
      it 'raises an exception if there are no chips to distribute' do
         initial_amount_in_side_pot = 0
         @player1.expects(:take_from_chip_stack!).once.with(initial_amount_in_side_pot)
      
         @patient = SidePot.new @player1, initial_amount_in_side_pot
      
         @players_and_their_contributions = {@player1 => [initial_amount_in_side_pot]}
      
         @patient.players_involved_and_their_amounts_contributed.should eq(@players_and_their_contributions)
         
         expect{@patient.distribute_chips! mock('BoardCards')}.to raise_exception(SidePot::NoChipsToDistribute)
      end
      it 'raises an exception if there are no players to take chips' do
         pending 'multiplayer support'
         #expect{@patient.distribute_chips!}.to raise_exception(SidePot::NoPlayersToTakeChips)
      end
   end
   
   def setup_succeeding_test
      @initial_amount_in_side_pot = 10
      @player1.expects(:take_from_chip_stack!).once.with(@initial_amount_in_side_pot)
      
      @patient = SidePot.new @player1, @initial_amount_in_side_pot
      
      @players_and_their_contributions = {@player1 => [@initial_amount_in_side_pot]}
      
      @patient.players_involved_and_their_amounts_contributed.should be == @players_and_their_contributions
      
      @players_and_their_contributions[@player2] = [0]
   end
   
   def calling_test(player=@player2, other_player=@player1, round=0)
      @players_and_their_contributions[player] = [] unless @players_and_their_contributions[player]
      @players_and_their_contributions[player][round] = 0 unless @players_and_their_contributions[player].length > round
      amount_to_call = @players_and_their_contributions[other_player].sum - @players_and_their_contributions[player].sum
      
      player.expects(:take_from_chip_stack!).once.with(amount_to_call)
      
      @players_and_their_contributions[player] = [] unless @players_and_their_contributions[player]
      @players_and_their_contributions[player][round] = 0 unless @players_and_their_contributions[player].length > round
      @players_and_their_contributions[player][round] += amount_to_call
      
      @patient.take_call! player
         
      @patient.players_involved_and_their_amounts_contributed.should be == @players_and_their_contributions
   end
   
   def betting_test(player=@player1, round=0)
      @amount_to_bet = 34
      player.expects(:take_from_chip_stack!).once.with(@amount_to_bet)
      
      @players_and_their_contributions[player][round] = 0 unless @players_and_their_contributions[player].length > round
      @players_and_their_contributions[player][round] += @amount_to_bet
      
      @patient.take_bet! player, @amount_to_bet
      
      @patient.players_involved_and_their_amounts_contributed.should be == @players_and_their_contributions
   end
   
   def raising_test(player=@player2, other_player=@player1, round=0)
      amount_player_has_contributed_over_hand = @players_and_their_contributions[player].sum
      amount_to_call = @players_and_their_contributions[other_player].sum - amount_player_has_contributed_over_hand
      
      @amount_to_raise_by = 67
      @amount_to_raise_to = amount_player_has_contributed_over_hand + amount_to_call + @amount_to_raise_by
      player.expects(:take_from_chip_stack!).once.with(amount_to_call)
      player.expects(:take_from_chip_stack!).once.with(@amount_to_raise_by)
      
      @players_and_their_contributions[player] = [] unless @players_and_their_contributions[player]
      @players_and_their_contributions[player][round] = 0 unless @players_and_their_contributions[player].length > round
      @players_and_their_contributions[player][round] += amount_to_call + @amount_to_raise_by
      
      @patient.take_raise! player, @amount_to_raise_to
      
      @patient.players_involved_and_their_amounts_contributed.should be == @players_and_their_contributions
   end
   
   def test_chip_distribution(board_cards)
      @players_and_their_contributions = {}
         
      @patient.distribute_chips! board_cards
         
      @patient.should be == 0
      @patient.players_involved_and_their_amounts_contributed.should be == @players_and_their_contributions
   end
   
   def play_through_all_rounds
      setup_succeeding_test
      
      calling_test
      MAX_VALUES[:rounds].times do |round|
         @patient.round = round
         betting_test @player1, round
         raising_test @player2, @player1, round
         calling_test @player1, @player2, round
      end
   end
   
   def distributes_chips_properly_when_one_player_left(chips_to_distribute)
      @patient.should be == chips_to_distribute
      
      @player1.stubs(:has_folded).returns(false)
      @player2.stubs(:has_folded).returns(true)
      @player1.expects(:take_winnings!).once.with(chips_to_distribute)
      
      test_chip_distribution mock('BoardCards')
   end
   
   def distributes_chips_properly_when_two_players_left_equal_strength(chips_to_distribute)
      @patient.should be == chips_to_distribute
      
      @player1.stubs(:has_folded).returns(false)
      @player2.stubs(:has_folded).returns(false)
      hand = mock 'Hand'
      @player1.stubs(:hole_cards).returns(hand)
      @player2.stubs(:hole_cards).returns(hand)
      
      pile_of_cards = mock 'PileOfCards'
      pile_of_cards.stubs(:to_poker_hand_strength).returns(5)
      PileOfCards.stubs(:new).returns(pile_of_cards)
      
      board_cards = mock 'BoardCards'
      board_cards.stubs(:+).returns(pile_of_cards)
      
      @player1.expects(:take_winnings!).once.with(chips_to_distribute/2)
      @player2.expects(:take_winnings!).once.with(chips_to_distribute/2)
      
      test_chip_distribution board_cards
   end
   
   def distributes_chips_properly_when_two_players_left_unequal_strength(chips_to_distribute)
      @patient.should be == chips_to_distribute
      
      @player1.stubs(:has_folded).returns(false)
      @player2.stubs(:has_folded).returns(false)
      hand1 = mock 'Hand'
      hand2 = mock 'Hand'
      @player1.stubs(:hole_cards).returns(hand1)
      @player2.stubs(:hole_cards).returns(hand2)
      
      pile_of_cards1 = mock 'PileOfCards'
      pile_of_cards1.stubs(:to_poker_hand_strength).returns(9)
      PileOfCards.stubs(:new).with(pile_of_cards1).returns(pile_of_cards1)
      
      pile_of_cards2 = mock 'PileOfCards'
      pile_of_cards2.stubs(:to_poker_hand_strength).returns(10)
      PileOfCards.stubs(:new).with(pile_of_cards2).returns(pile_of_cards2)
      
      board_cards = mock 'BoardCards'
      board_cards.stubs(:+).once.with(hand1).returns(pile_of_cards1)
      board_cards.stubs(:+).once.with(hand2).returns(pile_of_cards2)
      
      @player2.expects(:take_winnings!).once.with(chips_to_distribute)
      
      test_chip_distribution board_cards
   end
end
