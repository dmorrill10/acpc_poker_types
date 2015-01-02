
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'hand_evaluator'
require_relative '../lib/acpc_poker_types/card'
require_relative '../lib/acpc_poker_types/pile_of_cards'
require_relative '../lib/acpc_poker_types/rank'
require_relative '../lib/acpc_poker_types/suit'

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
  end

  describe '#to_poker_hand_description' do
    it 'works for royal flush' do
      AcpcPokerTypes::PileOfCards.new(
        [
          AcpcPokerTypes::Card.from_acpc('Ah'),
          AcpcPokerTypes::Card.from_acpc('Kh'),
          AcpcPokerTypes::Card.from_acpc('Qh'),
          AcpcPokerTypes::Card.from_acpc('Jh'),
          AcpcPokerTypes::Card.from_acpc('Th'),
          AcpcPokerTypes::Card.from_acpc('2s'),
          AcpcPokerTypes::Card.from_acpc('5c')
        ]
      ).to_poker_hand_key.must_equal(:royal_flush)
    end
    describe 'straight flush' do
      it 'works for the smallest straight flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('5h'),
            AcpcPokerTypes::Card.from_acpc('4h'),
            AcpcPokerTypes::Card.from_acpc('3h'),
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:straight_flush)
      end
      it 'works for a larger straight flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Th'),
            AcpcPokerTypes::Card.from_acpc('9h'),
            AcpcPokerTypes::Card.from_acpc('8h'),
            AcpcPokerTypes::Card.from_acpc('7h'),
            AcpcPokerTypes::Card.from_acpc('6h'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:straight_flush)
      end
    end
    describe 'four of a kind' do
      it 'works for the smallest four of a kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2d'),
            AcpcPokerTypes::Card.from_acpc('2s')
          ]
        ).to_poker_hand_key.must_equal(:four_of_a_kind)
      end
      it 'works for a larger four of a kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Th'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('Td'),
            AcpcPokerTypes::Card.from_acpc('Ts'),
            AcpcPokerTypes::Card.from_acpc('6h'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:four_of_a_kind)
      end
    end
    describe 'full house' do
      it 'works for the smallest full house' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2d'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('3h'),
            AcpcPokerTypes::Card.from_acpc('6s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:full_house)
      end
      it 'works for a larger full house' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Th'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('Td'),
            AcpcPokerTypes::Card.from_acpc('6s'),
            AcpcPokerTypes::Card.from_acpc('6h'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:full_house)
      end
    end
    describe 'flush' do
      it 'works for the smallest flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('3c'),
            AcpcPokerTypes::Card.from_acpc('4c'),
            AcpcPokerTypes::Card.from_acpc('5c'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('6s'),
            AcpcPokerTypes::Card.from_acpc('Th')
          ]
        ).to_poker_hand_key.must_equal(:flush)
      end
      it 'works for a larger flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Qc'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('3c'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:flush)
      end
    end
    describe 'straight' do
      it 'works for the smallest straight' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('3h'),
            AcpcPokerTypes::Card.from_acpc('4s'),
            AcpcPokerTypes::Card.from_acpc('5d'),
            AcpcPokerTypes::Card.from_acpc('Ac'),
            AcpcPokerTypes::Card.from_acpc('8s'),
            AcpcPokerTypes::Card.from_acpc('Th')
          ]
        ).to_poker_hand_key.must_equal(:straight)
      end
      it 'works for a larger straight' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('9h'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:straight)
      end
    end
    describe 'three of a kind' do
      it 'works for the smallest three_of_a_kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('2s')
          ]
        ).to_poker_hand_key.must_equal(:three_of_a_kind)
      end
      it 'works for a larger three_of_a_kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Js'),
            AcpcPokerTypes::Card.from_acpc('Jh'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:three_of_a_kind)
      end
    end
    describe 'two pair' do
      it 'works for the smallest two pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('3d')
          ]
        ).to_poker_hand_key.must_equal(:two_pair)
      end
      it 'works for a larger two pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Js'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('Ad'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:two_pair)
      end
    end
    describe 'one pair' do
      it 'works for the smallest one pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2h')
          ]
        ).to_poker_hand_key.must_equal(:one_pair)
      end
      it 'works for a larger one pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Js'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:one_pair)
      end
    end
    describe 'high card' do
      it 'works for the smallest high card' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c')
          ]
        ).to_poker_hand_key.must_equal(:high_card)
      end
      it 'works for a larger high card' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_key.must_equal(:high_card)
      end
    end
  end

  describe '#to_poker_hand_description' do
    it 'works for royal flush' do
      AcpcPokerTypes::PileOfCards.new(
        [
          AcpcPokerTypes::Card.from_acpc('Ah'),
          AcpcPokerTypes::Card.from_acpc('Kh'),
          AcpcPokerTypes::Card.from_acpc('Qh'),
          AcpcPokerTypes::Card.from_acpc('Jh'),
          AcpcPokerTypes::Card.from_acpc('Th'),
          AcpcPokerTypes::Card.from_acpc('2s'),
          AcpcPokerTypes::Card.from_acpc('5c')
        ]
      ).to_poker_hand_description.must_equal('royal flush')
    end
    describe 'straight flush' do
      it 'works for the smallest straight flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('5h'),
            AcpcPokerTypes::Card.from_acpc('4h'),
            AcpcPokerTypes::Card.from_acpc('3h'),
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal('five-high straight flush')
      end
      it 'works for a larger straight flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Th'),
            AcpcPokerTypes::Card.from_acpc('9h'),
            AcpcPokerTypes::Card.from_acpc('8h'),
            AcpcPokerTypes::Card.from_acpc('7h'),
            AcpcPokerTypes::Card.from_acpc('6h'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal('ten-high straight flush')
      end
    end
    describe 'four of a kind' do
      it 'works for the smallest four of a kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2d'),
            AcpcPokerTypes::Card.from_acpc('2s')
          ]
        ).to_poker_hand_description.must_equal("quad twos")
      end
      it 'works for a larger four of a kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Th'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('Td'),
            AcpcPokerTypes::Card.from_acpc('Ts'),
            AcpcPokerTypes::Card.from_acpc('6h'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal("quad tens with six kicker")
      end
    end
    describe 'full house' do
      it 'works for the smallest full house' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2d'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('3h'),
            AcpcPokerTypes::Card.from_acpc('6s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal("twos full of threes")
      end
      it 'works for a larger full house' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Th'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('Td'),
            AcpcPokerTypes::Card.from_acpc('6s'),
            AcpcPokerTypes::Card.from_acpc('6h'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal("tens full of sixes")
      end
    end
    describe 'flush' do
      it 'works for the smallest flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('3c'),
            AcpcPokerTypes::Card.from_acpc('4c'),
            AcpcPokerTypes::Card.from_acpc('5c'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('6s'),
            AcpcPokerTypes::Card.from_acpc('Th')
          ]
        ).to_poker_hand_description.must_equal("seven, five, four, three, two flush")
      end
      it 'works for a larger flush' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Qc'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('3c'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal("queen, ten, five, three, two flush")
      end
    end
    describe 'straight' do
      it 'works for the smallest straight' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('3h'),
            AcpcPokerTypes::Card.from_acpc('4s'),
            AcpcPokerTypes::Card.from_acpc('5d'),
            AcpcPokerTypes::Card.from_acpc('Ac'),
            AcpcPokerTypes::Card.from_acpc('8s'),
            AcpcPokerTypes::Card.from_acpc('Th')
          ]
        ).to_poker_hand_description.must_equal("five-high straight")
      end
      it 'works for a larger straight' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Tc'),
            AcpcPokerTypes::Card.from_acpc('9h'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal("jack-high straight")
      end
    end
    describe 'three of a kind' do
      it 'works for the smallest three_of_a_kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('2s')
          ]
        ).to_poker_hand_description.must_equal("trip twos")
      end
      it 'works for a larger three_of_a_kind' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Js'),
            AcpcPokerTypes::Card.from_acpc('Jh'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal(
          "trip jacks with eight and seven"
        )
      end
    end
    describe 'two pair' do
      it 'works for the smallest two pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2h'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('3d')
          ]
        ).to_poker_hand_description.must_equal('threes and twos')
      end
      it 'works for a larger two pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Js'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('Ad'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal('aces and jacks with seven kicker')
      end
    end
    describe 'one pair' do
      it 'works for the smallest one pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c'),
            AcpcPokerTypes::Card.from_acpc('2h')
          ]
        ).to_poker_hand_description.must_equal('pair of twos')
      end
      it 'works for a larger one pair' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('Js'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal('pair of jacks with ace, eight, and seven')
      end
    end
    describe 'high card' do
      it 'works for the smallest high card' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('2c')
          ]
        ).to_poker_hand_description.must_equal('two')
      end
      it 'works for a larger high card' do
        AcpcPokerTypes::PileOfCards.new(
          [
            AcpcPokerTypes::Card.from_acpc('Jc'),
            AcpcPokerTypes::Card.from_acpc('3s'),
            AcpcPokerTypes::Card.from_acpc('Ah'),
            AcpcPokerTypes::Card.from_acpc('8d'),
            AcpcPokerTypes::Card.from_acpc('7c'),
            AcpcPokerTypes::Card.from_acpc('2s'),
            AcpcPokerTypes::Card.from_acpc('5c')
          ]
        ).to_poker_hand_description.must_equal('ace, jack, eight, seven, and five')
      end
    end
  end

  def for_every_card
    AcpcPokerTypes::Rank::DOMAIN.map do |rank, rank_properties|
      AcpcPokerTypes::Suit::DOMAIN.map do |suit, suit_properties|
        yield AcpcPokerTypes::Card.from_components(rank, suit)
      end
    end
  end
end
