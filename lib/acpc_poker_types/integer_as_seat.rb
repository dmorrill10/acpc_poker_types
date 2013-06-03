require 'acpc_poker_types/seat'
module AcpcPokerTypes
  module IntegerAsSeat
    refine Integer do
      include SeatLike
    end
  end
end