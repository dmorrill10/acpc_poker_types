
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)


require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/hand", __FILE__)

describe Hand do
  describe '#initialize' do
    it 'understands every possible card combination' do
      for_every_two_cards! do |card_1, card_2|
        @patient = Hand.new [card_1, card_2]

        check_patient
      end
    end
  end
  describe '#from_acpc' do
    it 'understands every possible ACPC string hand' do
      for_every_two_cards! do |card_1, card_2|
        @patient = Hand.from_acpc @acpc

        check_patient
      end
    end
  end
  describe '#draw_cards' do
    it 'understands every possible card combination' do
      for_every_two_cards! do |card_1, card_2|
        @patient = Hand.draw_cards card_1, card_2

        check_patient
      end
    end
  end

  def check_patient
    @patient.to_s.should be == @string
    @patient.to_acpc.should be == @acpc
  end
  def for_every_card
    Rank::DOMAIN.map do |rank, rank_properties|
      Suit::DOMAIN.map do |suit, suit_properties|
        yield Card.from_components(rank, suit)
      end
    end
  end
  def for_every_two_cards!
    for_every_card do |first_card| 
      for_every_card do |second_card|
        @string = first_card.to_s + second_card.to_s
        @acpc = first_card.to_acpc + second_card.to_acpc

        yield first_card, second_card
      end
    end
  end
end
