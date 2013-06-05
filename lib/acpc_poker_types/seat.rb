require 'delegate'

module AcpcPokerTypes
  class Seat < DelegateClass(Integer)
    attr_reader :seat, :table_size

    # @return [Bool] Reports whether or not +seat+ represents an out of
    #   bounds seat for the number of seats, +num_seats+.
    def self.in_bounds?(seat, num_seats)
      seat < num_seats && seat >= 0
    end

    def initialize(seat, num_seats_at_table)
      @seat = seat.to_i
      @table_size = num_seats_at_table.to_i

      unless in_bounds?
        raise "Seat #{@seat} out of bounds for #{num_seats_at_table} players"
      end

      super @seat
    end
    def seats_to(other_seat_number)
      other_seat = self.class.new(other_seat_number, @table_size)

      if @seat > other_seat
        other_seat + @table_size
      else
        other_seat
      end - @seat
    end
    def seats_from(other_seat_number)
      Seat.new(other_seat_number, @table_size).seats_to(@seat)
    end
    def n_seats_away(n)
      Seat.new((n + @seat) % @table_size, @table_size)
    end
    def in_bounds?
      self.class.in_bounds?(@seat, @table_size)
    end
  end
end