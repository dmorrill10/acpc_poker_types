
require File.expand_path('../pile_of_cards', __FILE__)
require File.expand_path('../card', __FILE__)

class Hand < PileOfCards
  # @return [Hand]
  def self.draw_cards(*cards)
    Hand.new cards
  end

  # @param [String] acpc_string_hand ACPC string description of a hand.
  # @return [Hand]
  def self.from_acpc(acpc_string_hand)
    Hand.new Card.cards(acpc_string_hand)
  end

  def to_s
    join
  end

  alias_method :to_str, :to_s

  def to_acpc
    (map { |card| card.to_acpc }).join
  end
end
