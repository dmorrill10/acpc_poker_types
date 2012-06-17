
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require File.expand_path("#{LIB_ACPC_POKER_TYPES_PATH}/card", __FILE__)

describe Card do
  describe '::from_acpc' do
    it 'raises an exception if the given ACPC card string could not be parsed properly' do
      expect do 
        Card.from_acpc('not a card')
      end.to raise_exception(Card::UnableToParseAcpcCard)
    end
    it 'works properly in all cases' do
      for_every_card! do
        @patient = Card.from_acpc @acpc

        check_patient

        @patient = Card.from_components @rank, @suit

        check_patient

        @patient = Card.from_components @rank.to_sym, @suit.to_sym

        check_patient

        @patient = Card.from_components @rank.to_s, @suit.to_i

        check_patient
      end
    end
  end

  def for_every_card!
    Rank::DOMAIN.map do |rank, rank_properties|
      @rank = Rank.new rank
      Suit::DOMAIN.map do |suit, suit_properties|
        @suit = Suit.new suit
        @number = acpc_card_number @rank, @suit
        @string = rank_properties[:text] + suit_properties[:acpc_character]
        @acpc = rank_properties[:acpc_character] + suit_properties[:acpc_character]

        yield
      end
    end
  end

  def acpc_card_number(rank, suit)
    rank.to_i * Suit::DOMAIN.length + suit.to_i
  end

  def check_patient
    @patient.rank.to_sym.should == @rank.to_sym
    @patient.suit.to_sym.should == @suit.to_sym
    @patient.to_i.should == @number
    @patient.to_s.should == @string
    @patient.to_str.should == @string
    @patient.to_acpc.should == @acpc
  end
end