
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require File.expand_path('../../lib/hand_evaluator', __FILE__)
require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/card", __FILE__)

require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/pile_of_cards", __FILE__)

describe PileOfCards do
  describe '#to_poker_hand_strength' do
    it 'attributes zero hand strength to an empty hand' do
      patient = PileOfCards.new
      hand_strength = 0

      patient.to_poker_hand_strength.to_i.should be == hand_strength
    end
    it "can calculate the Texas hold'em poker hand strength for itself for a seven card set" do
      patient = PileOfCards.new
      cards = []
      for_every_card do |card|
        patient << card
        cards << card
        break if 7 == cards.length
      end
      hand_strength = HandEvaluator.rank_hand cards.map { |card| card.to_i }

      patient.to_poker_hand_strength.should be == hand_strength
    end
    it 'attributes the maximum hand strength to a hand with all the cards in the deck' do
      patient = PileOfCards.new
      cards = []
      for_every_card do |card|
        patient << card
        cards << card
      end
      hand_strength = HandEvaluator.rank_hand cards.map { |card| card.to_i }

      patient.to_poker_hand_strength.should be == hand_strength
    end

    def for_every_card
      Rank::DOMAIN.map do |rank, rank_properties|
        Suit::DOMAIN.map do |suit, suit_properties|
          yield Card.from_components(rank, suit)
        end
      end
    end
  end
end
