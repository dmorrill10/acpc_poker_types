
require 'acpc_poker_types/pile_of_cards'
require 'acpc_poker_types/card'

module AcpcPokerTypes
  class Hand < AcpcPokerTypes::PileOfCards
    # @return [Hand]
    def self.draw_cards(*cards)
      AcpcPokerTypes::Hand.new cards
    end

    # @param [String] acpc_string_hand ACPC string description of a hand.
    # @return [Hand]
    def self.from_acpc(acpc_string_hand)
      AcpcPokerTypes::Hand.new AcpcPokerTypes::Card.cards(acpc_string_hand)
    end

    def to_s
      join
    end

    alias_method :to_str, :to_s

    def to_acpc
      (map { |card| card.to_acpc }).join
    end
  end
end