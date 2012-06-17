
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require "#{LIB_ACPC_POKER_TYPES_PATH}/card"

require "#{LIB_ACPC_POKER_TYPES_PATH}/board_cards"

describe BoardCards do
  describe '#to_s' do
    it 'prints itself properly' do
      @patient = BoardCards.new

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

  def check_patient() @patient.to_s.should == @string end
  def for_every_card
    Rank::DOMAIN.map do |rank, rank_properties|
      Suit::DOMAIN.map do |suit, suit_properties|
        yield Card.from_components(rank, suit)
      end
    end
  end
  def for_many_rounds
    25.times do |round|
      yield round
    end
  end
end
