
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require "acpc_poker_types/card"

require 'acpc_poker_types/board_cards'

describe AcpcPokerTypes::BoardCards do
  describe '#to_s' do
    it 'prints itself properly' do
      @patient = AcpcPokerTypes::BoardCards.new

      @string = ''

      check_patient

      for_many_rounds do |round|
        @string += '/'
        @patient.next_round! unless 0 == round
        for_every_card do |card|
          @patient << card
          @string += card.to_s

          check_patient
        end
      end
    end
  end

  def check_patient() @patient.to_s.must_equal @string end
  def for_every_card
    AcpcPokerTypes::Rank::DOMAIN.map do |rank, rank_properties|
      AcpcPokerTypes::Suit::DOMAIN.map do |suit, suit_properties|
        yield AcpcPokerTypes::Card.from_components(rank, suit)
      end
    end
  end
  def for_many_rounds
    25.times do |round|
      yield round
    end
  end
end
