
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'hand_evaluator'
require 'acpc_poker_types/card'
require 'acpc_poker_types/pile_of_cards'
require 'acpc_poker_types/rank'
require 'acpc_poker_types/suit'

describe AcpcPokerTypes::PileOfCards do
  describe '#to_poker_hand_strength' do
    it 'attributes zero hand strength to an empty hand' do
      patient = AcpcPokerTypes::PileOfCards.new
      hand_strength = 0

      patient.to_poker_hand_strength.to_i.must_equal hand_strength
    end
    it "can calculate the Texas hold'em poker hand strength for itself for a seven card set" do
      patient = AcpcPokerTypes::PileOfCards.new
      cards = []
      for_every_card do |card|
        patient << card
        cards << card
        break if 7 == cards.length
      end
      hand_strength = HandEvaluator.rank_hand cards.map { |card| card.to_i }

      patient.to_poker_hand_strength.must_equal hand_strength
    end
    it 'attributes the maximum hand strength to a hand with all the cards in the deck' do
      patient = AcpcPokerTypes::PileOfCards.new
      cards = []
      for_every_card do |card|
        patient << card
        cards << card
      end
      hand_strength = HandEvaluator.rank_hand cards.map { |card| card.to_i }

      patient.to_poker_hand_strength.must_equal hand_strength
    end

    def for_every_card
      AcpcPokerTypes::Rank::DOMAIN.map do |rank, rank_properties|
        AcpcPokerTypes::Suit::DOMAIN.map do |suit, suit_properties|
          yield AcpcPokerTypes::Card.from_components(rank, suit)
        end
      end
    end
  end
end
