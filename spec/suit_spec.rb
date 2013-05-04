
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_poker_types/suit'

describe AcpcPokerTypes::Suit do
  describe '#new' do
    it 'raises an exception if the given suit is invalid' do
      -> {AcpcPokerTypes::Suit.new(:not_a_suit)}.must_raise(AcpcPokerTypes::Suit::UnrecognizedSuit)
    end
    describe 'correctly understands all suits' do
      it 'in symbol form' do
        for_every_suit do
          @patient = AcpcPokerTypes::Suit.new(@symbol)

          check_patient!
        end
      end
      it 'in ACPC form' do
        for_every_suit do
          @patient = AcpcPokerTypes::Suit.new(@acpc)

          check_patient!
        end
      end
      it 'in numeric ACPC form' do
        for_every_suit do
          @patient = AcpcPokerTypes::Suit.new(@number)

          check_patient!
        end
      end
      it 'in HTML form' do
        for_every_suit do
          @patient = AcpcPokerTypes::Suit.new(@html)

          check_patient!
        end
      end
      it 'in string form' do
        for_every_suit do
          @patient = AcpcPokerTypes::Suit.new(@string)

          check_patient!
        end
      end
    end
  end

  def for_every_suit
    AcpcPokerTypes::Suit::DOMAIN.each do |suit, properties|
      @symbol = suit
      @number = properties[:number]
      @string = properties[:acpc_character]
      @acpc = properties[:acpc_character]
      @html = properties[:html_character]

      yield
    end
  end

  def check_patient!
    @patient.to_sym.must_equal @symbol
    @patient.to_i.must_equal @number
    @patient.to_acpc.must_equal @acpc
    @patient.to_s.must_equal @string
    @patient.to_html.must_equal @html
  end
end
