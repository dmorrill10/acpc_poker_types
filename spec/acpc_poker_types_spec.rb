require_relative 'support/spec_helper.rb'
require_relative '../lib/acpc_poker_types.rb'

include AcpcPokerTypes

describe AcpcPokerTypes do
  before do
    @l_game_def = GameDefinition.parse(
      '
GAMEDEF
limit
numPlayers = 2
numRounds = 4
blind = 10 5
raiseSize = 10 10 20 20
firstPlayer = 2 1 1 1
maxRaises = 3 4 4 4
numSuits = 4
numRanks = 13
numHoleCards = 2
numBoardCards = 0 3 1 1
END GAMEDEF
      '.split("\n")
    )
    @nl_game_def = GameDefinition.parse(
      '
GAMEDEF
nolimit
numPlayers = 2
numRounds = 4
stack = 20000 20000
blind = 100 50
firstPlayer = 2 1 1 1
numSuits = 4
numRanks = 13
numHoleCards = 2
numBoardCards = 0 3 1 1
END GAMEDEF
      '.split("\n")
    )
  end

  it 'when player A calls a bet of 100 the log would say: A calls (100)' do
    call_description(
      'A',
      PokerAction.new('c', cost: 100)
    ).must_equal 'A calls (100)'
  end

  describe "no-limit hold'em" do
    it 'when player A bets by 500 to 700: A bets by 500 to 700' do
      bet_description(
        'A',
        PokerAction.new('b700', cost: 500)
      ).must_equal 'A bets by 500 to 700'
    end
    it 'when player B raises by 500 to 700 after player A bet by 100 to 200: B calls (100) and raises by 500 to 700' do
      no_limit_raise_description(
        'B',
        PokerAction.new('r700', cost: 500),
        100
      ).must_equal 'B calls (100) and raises by 500 to 700'
    end
  end

  describe "limit hold'em" do
    it 'when player A bets: A bets' do
      bet_description(
        'A',
        PokerAction.new('b', cost: 500)
      ).must_equal 'A bets'
    end
    it 'when player B raises after player A bet in a round with a maximum of four wagers: B calls and raises (#2 of 4)' do
      limit_raise_description(
        'B',
        PokerAction.new('r', cost: 500),
        1,
        4
      ).must_equal 'B calls and raises (#2 of 4)'
    end
  end

  it 'when player A checks: A checks' do
    check_description('A').must_equal 'A checks'
  end
  it 'when player A folds: A folds' do
    fold_description('A').must_equal 'A folds'
  end
  it 'when the xth hand is dealt by player A, and A is small blind, while player B is big blind: hand #x of y dealt by A, A pays SB (5), B pays BB (10)' do
    x = 23
    y = 100
    p1 = 'A'
    p2 = 'B'
    hand_dealt_description(
      [p1, p2],
      x,
      @l_game_def,
      y
    ).must_equal "hand ##{x} of #{y} dealt by #{p1}, #{p1} pays SB (#{@l_game_def.blinds.min}), #{p2} pays BB (#{@l_game_def.blinds.max})"
  end

  describe 'hand result messages' do
    it 'when player A wins 1000 to increase their balance to 2000: A wins 1000, bringing their balance to 2000' do
      player = 'A'
      amount_won = 1000
      current_balance = 2000
      hand_win_description(
        player,
        amount_won,
        current_balance
      ).must_equal "#{player} wins #{amount_won}, bringing their balance to #{current_balance + amount_won}"
    end

    describe '#split_pot_description' do
      it 'when players A and B split the bot of 1000: A and B split the pot, each winning 500' do
        split_pot_description(
          ['A', 'B'],
          1000
        ).must_equal 'A and B split the pot, each winning 500'
      end

      it 'when players A, B, and C split the bot of 1000: A, B, and C split the pot, each winning 333.' do
        split_pot_description(
          ['A', 'B', 'C'],
          1000
        ).must_equal 'A, B, and C split the pot, each winning 333.33'
      end
    end
  end

  describe '#dealer_index, #big_blind_payer_index, and #small_blind_payer_index' do
    it 'should return the index of the big blind on the first hand' do
      dealer_index(0, @l_game_def).must_equal 1
      big_blind_payer_index(0, @l_game_def).must_equal 0
      small_blind_payer_index(0, @l_game_def).must_equal 1
    end
    it 'should work on every other hand' do
      dealer_index(1, @l_game_def).must_equal 0
      big_blind_payer_index(1, @l_game_def).must_equal 1
      small_blind_payer_index(1, @l_game_def).must_equal 0
      dealer_index(2, @l_game_def).must_equal 1
      big_blind_payer_index(2, @l_game_def).must_equal 0
      small_blind_payer_index(2, @l_game_def).must_equal 1
      dealer_index(3, @l_game_def).must_equal 0
      big_blind_payer_index(3, @l_game_def).must_equal 1
      small_blind_payer_index(3, @l_game_def).must_equal 0
      dealer_index(4, @l_game_def).must_equal 1
      big_blind_payer_index(4, @l_game_def).must_equal 0
      small_blind_payer_index(4, @l_game_def).must_equal 1
      dealer_index(5, @l_game_def).must_equal 0
      big_blind_payer_index(5, @l_game_def).must_equal 1
      small_blind_payer_index(5, @l_game_def).must_equal 0
    end
  end
end
