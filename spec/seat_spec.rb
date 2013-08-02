require_relative 'support/spec_helper'

require 'acpc_poker_types/seat'

include AcpcPokerTypes

describe Seat do
  it 'acts like an integer' do
    x_int = 2
    patient = Seat.new x_int, 4

    patient.must_equal x_int
    (patient + x_int).must_equal x_int * 2
  end
  it 'accepts players as well as seats' do
    Struct.new 'Player', :seat

    x_player = Struct::Player.new(1)
    Seat.new(x_player, 4).must_equal x_player.seat
  end
  it 'accepts seats that are larger than the table size by wrapping' do
    x_seat = 2

    Seat.new(5, 3).must_equal x_seat
  end
  describe '#seats_to' do
    it 'works for seats on the left' do
      Seat.new(2, 5).seats_to(4).must_equal 2
    end
    it 'works for seats on the right' do
      Seat.new(2, 5).seats_to(0).must_equal 3
    end
    it 'works for its own seat' do
      Seat.new(1, 2).seats_to(1).must_equal 0
    end
  end
  describe '#seats_from' do
    it 'works for seats on the left' do
      Seat.new(2, 5).seats_from(4).must_equal 3
    end
    it 'works for seats on the right' do
      Seat.new(2, 5).seats_from(0).must_equal 2
    end
    it 'works for its own seat' do
      Seat.new(1, 2).seats_from(1).must_equal 0
    end
  end
  describe '#n_seats_away' do
    it 'works for positive n' do
      Seat.new(2, 5).n_seats_away(2).must_equal 4
    end
    it 'works for negative n' do
      Seat.new(2, 5).n_seats_away(-2).must_equal 0
    end
    it 'works for n larger than the size of the table' do
      Seat.new(1, 5).n_seats_away(8).must_equal 4
    end
  end
end
