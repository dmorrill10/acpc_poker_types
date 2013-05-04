
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require "acpc_poker_types/rank"

describe AcpcPokerTypes::Rank do
  describe '#new' do
    it 'raises an exception if the given rank is invalid' do
      ->{AcpcPokerTypes::Rank.new(:not_a_rank)}.must_raise(AcpcPokerTypes::Rank::UnrecognizedRank)
    end
    describe 'correctly understands all ranks' do
      it 'in symbol form' do
        for_every_rank do
          @patient = AcpcPokerTypes::Rank.new(@symbol)

          check_patient!
        end
      end
      it 'in ACPC form' do
        for_every_rank do
          @patient = AcpcPokerTypes::Rank.new(@acpc)

          check_patient!
        end
      end
      it 'in numeric ACPC form' do
        for_every_rank do
          @patient = AcpcPokerTypes::Rank.new(@number)

          check_patient!
        end
      end
      it 'in HTML form' do
        for_every_rank do
          @patient = AcpcPokerTypes::Rank.new(@html)

          check_patient!
        end
      end
      it 'in string form' do
        for_every_rank do
          @patient = AcpcPokerTypes::Rank.new(@string)

          check_patient!
        end
      end
    end
  end

  def for_every_rank
    AcpcPokerTypes::Rank::DOMAIN.each do |rank, properties|
      @symbol = rank
      @number = properties[:number]
      @string = properties[:text]
      @acpc = properties[:acpc_character]
      @html = properties[:text]

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
