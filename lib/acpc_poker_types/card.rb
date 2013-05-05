
require 'dmorrill10-utils'

require 'acpc_poker_types/rank'
require 'acpc_poker_types/suit'

class AcpcPokerTypes::Card
  CONCATONATED_RANKS = (AcpcPokerTypes::Rank::DOMAIN.map { |rank, properties| properties[:acpc_character] }).join
  CONCATONATED_SUITS = (AcpcPokerTypes::Suit::DOMAIN.map { |suit, properties| properties[:acpc_character] }).join
  CONCATONATED_CARDS = CONCATONATED_RANKS + CONCATONATED_SUITS

  # @param [String] acpc_string_of_cards A string of cards in ACPC format
  # @return [Array<AcpcPokerTypes::Card>]
  def self.cards(acpc_string_of_cards)
    acpc_string_of_cards.scan(/[#{CONCATONATED_RANKS}][#{CONCATONATED_SUITS}]/).map do |acpc_card|
      AcpcPokerTypes::Card.from_acpc(acpc_card)
    end
  end

  # @return [Integer] The numeric ACPC representation of the card.
  def self.acpc_card_number(rank, suit)
    rank.to_i * AcpcPokerTypes::Suit::DOMAIN.length + suit.to_i
  end

  attr_reader :rank, :suit

  # @return AcpcPokerTypes::Card
  def self.from_acpc(acpc_card)
    rank = acpc_card[0]
    suit = acpc_card[1]

    AcpcPokerTypes::Card.from_components rank, suit
  end

  alias_new :from_components

  def initialize(rank, suit)
    @rank = AcpcPokerTypes::Rank.new rank
    @suit = AcpcPokerTypes::Suit.new suit
  end

  def to_i
    AcpcPokerTypes::Card.acpc_card_number(@rank, @suit)
  end

  def to_str
    @rank.to_s + @suit.to_s
  end

  alias_method :to_s, :to_str

  def to_acpc
    @rank.to_acpc + @suit.to_acpc
  end
end
