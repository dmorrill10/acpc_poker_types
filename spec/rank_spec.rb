
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require "#{LIB_ACPC_POKER_TYPES_PATH}/rank"

describe Rank do
  describe '#new' do
    it 'raises an exception if the given rank is invalid' do
      expect{Rank.new(:not_a_rank)}.to raise_exception(Rank::UnrecognizedRank)
    end
    describe 'correctly understands all ranks' do
      it 'in symbol form' do
        for_every_rank do
          @patient = Rank.new(@symbol)
          
          check_patient!
        end
      end
      it 'in ACPC form' do
        for_every_rank do
          @patient = Rank.new(@acpc)
          
          check_patient!
        end
      end
      it 'in numeric ACPC form' do
        for_every_rank do
          @patient = Rank.new(@number)
          
          check_patient!
        end
      end
      it 'in HTML form' do
        for_every_rank do
          @patient = Rank.new(@html)
          
          check_patient!
        end
      end
      it 'in string form' do
        for_every_rank do
          @patient = Rank.new(@string)
          
          check_patient!
        end
      end
    end
  end

  def for_every_rank
    Rank::DOMAIN.each do |rank, properties|
      @symbol = rank
      @number = properties[:number]
      @string = properties[:text]
      @acpc = properties[:acpc_character]
      @html = properties[:text]

      yield
    end
  end

  def check_patient!
    @patient.to_sym.should == @symbol
    @patient.to_i.should == @number
    @patient.to_acpc.should == @acpc
    @patient.to_s.should == @string
    @patient.to_html.should == @html
  end
end
