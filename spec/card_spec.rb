
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_poker_types/card'

describe AcpcPokerTypes::Card do
  describe '::from_acpc' do
    it 'works properly in all cases' do
      for_every_card! do
        @patient = AcpcPokerTypes::Card.from_acpc @acpc

        check_patient

        @patient = AcpcPokerTypes::Card.from_components @rank, @suit

        check_patient

        @patient = AcpcPokerTypes::Card.from_components @rank.to_sym, @suit.to_sym

        check_patient

        @patient = AcpcPokerTypes::Card.from_components @rank.to_s, @suit.to_i

        check_patient
      end
    end
  end

  def for_every_card!
    AcpcPokerTypes::Rank::DOMAIN.map do |rank, rank_properties|
      @rank = AcpcPokerTypes::Rank.new rank
      AcpcPokerTypes::Suit::DOMAIN.map do |suit, suit_properties|
        @suit = AcpcPokerTypes::Suit.new suit
        @number = acpc_card_number @rank, @suit
        @string = rank_properties[:text] + suit_properties[:acpc_character]
        @acpc = rank_properties[:acpc_character] + suit_properties[:acpc_character]

        yield
      end
    end
  end

  def acpc_card_number(rank, suit)
    rank.to_i * AcpcPokerTypes::Suit::DOMAIN.length + suit.to_i
  end

  def check_patient
    @patient.rank.to_sym.must_equal @rank.to_sym
    @patient.suit.to_sym.must_equal @suit.to_sym
    @patient.to_i.must_equal @number
    @patient.to_s.must_equal @string
    @patient.to_str.must_equal @string
    @patient.to_acpc.must_equal @acpc
  end
end