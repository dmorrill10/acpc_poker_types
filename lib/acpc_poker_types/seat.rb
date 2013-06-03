require 'delegate'

module AcpcPokerTypes
  module SeatLike
    # @param [Integer] seat The seat to which the relative position is desired.
    # @param [Integer] number_of_players The number of players at the table.
    # @return [Integer] The relative position of +self+ to +seat+, given the
    #  number of players at the table, +number_of_players+, indexed such that
    #  the seat immediately to the left of +seat+ has a +position_relative_to+ of
    #  zero.
    # @example <code>1.position_relative_to 0, 3</code> == 0
    # @example <code>1.position_relative_to 1, 3</code> == 2
    def position_relative_to(seat, number_of_players)
      unless seat.seat_in_bounds?(number_of_players) &&
        seat_in_bounds?(number_of_players)
        raise "Seat #{seat} out of bounds for #{number_of_players} players"
      end

      adjusted_seat = if self > seat
        self
      else
        self + number_of_players
      end
      adjusted_seat - seat - 1
    end

    # Inverse operation of +position_relative_to+.
    # Given
    #  <code>relative_position = seat.position_relative_to to_seat, number_of_players</code>
    # then
    #  <code>to_seat = seat.seat_from_relative_position relative_position, number_of_players</code>
    #
    # @param [Integer] relative_position_of_self_to_result The relative position
    #  of seat +self+ to the seat that is returned by this function.
    # @param [Integer] number_of_players The number of players at the table.
    # @return [Integer] The seat to which the relative position,
    #  +relative_position_of_self_to_result+, of +self+ was derived, given the
    #  number of players at the table, +number_of_players+, indexed such that
    #  the seat immediately to the left of +from_seat+ has a
    #  +position_relative_to+ of zero.
    # @example <code>1.seat_from_relative_position 0, 3</code> == 0
    # @example <code>1.seat_from_relative_position 2, 3</code> == 1
    def seat_from_relative_position(
      relative_position_of_self_to_result,
      number_of_players
    )
      unless seat_in_bounds?(number_of_players)
        raise "Seat #{seat} out of bounds for #{number_of_players} players"
      end

      unless relative_position_of_self_to_result.seat_in_bounds?(
        number_of_players
      )
        raise "Relative position #{relative_position_of_self_to_result} out of bounds for #{number_of_players} players"
      end

      position_adjustment = relative_position_of_self_to_result + 1

      to_seat = self.class.new(
        self + number_of_players - position_adjustment
      )
      if self > to_seat || !to_seat.seat_in_bounds?(number_of_players)
        self - position_adjustment
      else
        to_seat
      end
    end

    # @param [Integer] number_of_players The number of players at the table.
    # @return [Bool] Reports whether or not +self+ represents an out of bounds
    #  seat.
    def seat_in_bounds?(number_of_players)
      self < number_of_players && self >= 0
    end
  end

  class Seat < DelegateClass(Integer)
    include SeatLike

    def initialize(seat)
      @seat = seat.to_i
      super @seat
    end
  end
end