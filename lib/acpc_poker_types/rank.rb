require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerTypes
  class Rank
    exceptions :unrecognized_rank

    DOMAIN = {
      two: {acpc_character: '2', text: '2', number: 0},
      three: {acpc_character: '3', text: '3', number: 1},
      four: {acpc_character: '4', text: '4', number: 2},
      five: {acpc_character: '5', text: '5', number: 3},
      six: {acpc_character: '6', text: '6', number: 4},
      seven: {acpc_character: '7', text: '7', number: 5},
      eight: {acpc_character: '8', text: '8', number: 6},
      nine: {acpc_character: '9', text: '9', number: 7},
      ten: {acpc_character: 'T', text: '10', number: 8},
      jack: {acpc_character: 'J', text: 'J', number: 9},
      queen: {acpc_character: 'Q', text: 'Q', number: 10},
      king: {acpc_character: 'K', text: 'K', number: 11},
      ace: {acpc_character: 'A', text: 'A', number: 12}
    }

    def self.hash_from_rank_token(rank)
      if rank.kind_of?(Integer)
        DOMAIN.find do |rank_symbol, properties|
          properties[:number] == rank
        end
      else
        DOMAIN.find do |rank_symbol, properties|
          rank_symbol == rank.to_sym ||
          properties[:acpc_character] == rank.to_s ||
          properties[:text] == rank.to_s
        end
      end
    end

    def self.symbol_from_rank_token(rank)
      rank_hash = hash_from_rank_token rank

      raise UnrecognizedRank, rank.to_s unless rank_hash

      rank_hash.first
    end

    def initialize(rank)
      @symbol = AcpcPokerTypes::Rank.symbol_from_rank_token rank
    end

    def to_sym
      @symbol
    end

    def to_i
      DOMAIN[@symbol][:number]
    end

    def to_acpc
      DOMAIN[@symbol][:acpc_character]
    end

    def to_s
      DOMAIN[@symbol][:text]
    end

    alias_method :to_html, :to_s
    alias_method :to_str, :to_s
  end
end