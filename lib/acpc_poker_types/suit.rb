
require 'dmorrill10-utils'

class AcpcPokerTypes::Suit
  exceptions :unrecognized_suit

  DOMAIN = {
    clubs: {acpc_character: 'c', html_character: '&clubs;', number: 0},
    diamonds: {acpc_character: 'd', html_character: '&diams;', number: 1},
    hearts: {acpc_character: 'h', html_character: '&hearts;', number: 2},
    spades: {acpc_character: 's', html_character: '&spades;', number: 3}
  }

  def self.hash_from_suit_token(suit)
    if suit.kind_of?(Integer)
      DOMAIN.find do |suit_symbol, properties|
        properties[:number] == suit
      end
    else
      DOMAIN.find do |suit_symbol, properties|
        suit_symbol == suit.to_sym ||
        properties[:acpc_character] == suit.to_s ||
        properties[:html_character] == suit.to_s
      end
    end
  end

  def self.symbol_from_suit_token(suit)
    suit_hash = hash_from_suit_token suit

    raise UnrecognizedSuit, suit.to_s unless suit_hash

    suit_hash.first
  end

  def initialize(suit)
    @symbol = AcpcPokerTypes::Suit.symbol_from_suit_token suit
  end

  def to_sym
    @symbol
  end

  def to_i
    DOMAIN[@symbol][:number]
  end

  def to_acpc
    DOMAIN[@symbol][:acpc_character]
  end

  alias_method :to_s, :to_acpc
  alias_method :to_str, :to_s

  def to_html
    DOMAIN[@symbol][:html_character]
  end
end
