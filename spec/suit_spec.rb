
# Spec helper (must include first to track code coverage with SimpleCov)
require File.expand_path('../support/spec_helper', __FILE__)

require "#{LIB_ACPC_POKER_TYPES_PATH}/suit"

describe Suit do
  describe '#new' do
    it 'raises an exception if the given suit is invalid' do
      expect{Suit.new(:not_a_suit)}.to raise_exception(Suit::UnrecognizedSuit)
    end
    describe 'correctly understands all suits' do
      it 'in symbol form' do
        for_every_suit do
          @patient = Suit.new(@symbol)
          
          check_patient!
        end
      end
      it 'in ACPC form' do
        for_every_suit do
          @patient = Suit.new(@acpc)
          
          check_patient!
        end
      end
      it 'in numeric ACPC form' do
        for_every_suit do
          @patient = Suit.new(@number)
          
          check_patient!
        end
      end
      it 'in HTML form' do
        for_every_suit do
          @patient = Suit.new(@html)
          
          check_patient!
        end
      end
      it 'in string form' do
        for_every_suit do
          @patient = Suit.new(@string)
          
          check_patient!
        end
      end
    end
  end

  def for_every_suit
    Suit::DOMAIN.each do |suit, properties|
      @symbol = suit
      @number = properties[:number]
      @string = properties[:acpc_character]
      @acpc = properties[:acpc_character]
      @html = properties[:html_character]

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
