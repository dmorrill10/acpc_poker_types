
require 'dmorrill10-utils'

require File.expand_path('../rank', __FILE__)
require File.expand_path('../suit', __FILE__)

class Card

  exceptions :unable_to_parse_acpc_card

  # @return [Array<String>] A list of all possible ACPC cards.
  ACPC_CARDS = Rank::DOMAIN.map do |rank, rank_properties| 
    Suit::DOMAIN.map do |suit, suit_properties| 
      rank_properties[:acpc_character] + suit_properties[:acpc_character]
    end
  end.flatten

  # @return [Card]
  def self.from_acpc(acpc_card)
    all_ranks = Rank::DOMAIN.values.map do |card_rank|
      card_rank[:acpc_character]
    end.join
    all_suits = Suit::DOMAIN.values.map do |card_suit| 
      card_suit[:acpc_character] 
    end.join

    if acpc_card.match(/([#{all_ranks}])([#{all_suits}])/)
      rank = $1
      suit = $2

      Card.from_components rank, suit
    else
      raise UnableToParseAcpcCard, acpc_card
    end
  end

  # @return [Integer] The numeric ACPC representation of the card.
  def self.acpc_card_number(rank, suit)
    rank.to_i * Suit::DOMAIN.length + suit.to_i
  end

  attr_reader :rank, :suit

  alias_new :from_components

  def initialize(rank, suit)
    @rank = Rank.new rank
    @suit = Suit.new suit
  end

  def to_i
    Card.acpc_card_number(@rank, @suit)
  end

  def to_str
    @rank.to_s + @suit.to_s
  end

  alias_method :to_s, :to_str

  def to_acpc
    @rank.to_acpc + @suit.to_acpc
  end
end
