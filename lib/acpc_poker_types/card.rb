
require 'dmorrill10-utils'

require File.expand_path('../rank', __FILE__)
require File.expand_path('../suit', __FILE__)

class AcpcPokerTypes::Card
  exceptions :parse_error

  # @param [String] acpc_string_of_cards A string of cards in ACPC format
  # @return [Array<AcpcPokerTypes::Card>]
  def self.cards(acpc_string_of_cards)
    all_ranks = AcpcPokerTypes::Rank::DOMAIN.map do |rank, rank_properties|
     rank_properties[:acpc_character]
    end.join
    all_suits = AcpcPokerTypes::Suit::DOMAIN.map do |suit, suit_properties|
      suit_properties[:acpc_character]
    end.join

    acpc_string_of_cards.scan(/[#{all_ranks}][#{all_suits}]/).inject([]) do |pile, acpc_card|
      pile.push << AcpcPokerTypes::Card.from_acpc(acpc_card)
    end
  end

  # @return [Integer] The numeric ACPC representation of the card.
  def self.acpc_card_number(rank, suit)
    rank.to_i * AcpcPokerTypes::Suit::DOMAIN.length + suit.to_i
  end

  attr_reader :rank, :suit

  # @return AcpcPokerTypes::Card
  def self.from_acpc(acpc_card)
    all_ranks = AcpcPokerTypes::Rank::DOMAIN.values.map do |card_rank|
      card_rank[:acpc_character]
    end.join
    all_suits = AcpcPokerTypes::Suit::DOMAIN.values.map do |card_suit|
      card_suit[:acpc_character]
    end.join

    if acpc_card.match(/([#{all_ranks}])([#{all_suits}])/)
      rank = $1
      suit = $2

      AcpcPokerTypes::Card.from_components rank, suit
    else
      raise ParseError, acpc_card
    end
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
