require 'hand_evaluator'
require 'inflections'
require 'active_support'

module AcpcPokerTypes
  class PileOfCards < Array
    POKER_HAND_STRENGTHS = {
      royal_flush: 12115,
      straight_flush: 12106,
      four_of_a_kind: 11934,
      full_house: 10921,
      flush: 9634,
      straight: 9623,
      three_of_a_kind: 8606,
      two_pair: 5291,
      one_pair: 1287,
      high_card: 0
    }

    # @return [Integer] The strength of the strongest poker hand that can be made from this pile of cards.
    def to_poker_hand_strength
      HandEvaluator.rank_hand map { |card| card.to_i }
    end

    def to_poker_hand_key
      flattened_strengths = self.class().poker_hand_strengths_sorted_desc.flatten
      flattened_strengths[
        flattened_strengths.index do |e|
          e.respond_to?(:to_i) && e.to_i <= to_poker_hand_strength
        end - 1
      ]
    end

    def to_poker_hand_description
      case to_poker_hand_key
      when :royal_flush
        'royal flush'
      when :straight_flush
        "#{Rank.new(to_poker_hand_strength - POKER_HAND_STRENGTHS[:straight_flush] + 3).to_sym}-high straight flush"
      when :four_of_a_kind
        rank_with_quad = largest_rank(4)

        m = "quad #{ActiveSupport::Inflector.pluralize(rank_with_quad.to_sym.to_s)}"

        if length > 4
          kicker = remaining_cards(rank_with_quad, 4).largest_rank
          "#{m} with #{kicker.to_sym} kicker"
        else
          m
        end
      when :full_house
        rank_with_trip = largest_rank(3)
        rank_with_pair = remaining_cards(rank_with_trip, -1).largest_rank 2
        "#{ActiveSupport::Inflector.pluralize(rank_with_trip.to_sym.to_s)} full of #{ActiveSupport::Inflector.pluralize(rank_with_pair.to_sym.to_s)}"
      when :flush
        flush_with_largest_rank = nil
        largest_rank_so_far = -1
        Suit.every_suit do |suit|
          if count { |c| c.suit == suit } >= 5
            r = largest_rank 1, [suit]
            if r > largest_rank_so_far
              flush_with_largest_rank = suit
              largest_rank_so_far = r
            end
          end
        end
        cards = all_cards flush_with_largest_rank
        r1 = cards.largest_rank
        cards = cards.remaining_cards(r1)
        r2 = cards.largest_rank
        cards = cards.remaining_cards(r2)
        r3 = cards.largest_rank
        cards = cards.remaining_cards(r3)
        r4 = cards.largest_rank
        cards = cards.remaining_cards(r4)
        r5 = cards.largest_rank

        "#{r1.to_sym}, #{r2.to_sym}, #{r3.to_sym}, #{r4.to_sym}, #{r5.to_sym} flush"
      when :straight
        "#{Rank.new(to_poker_hand_strength - POKER_HAND_STRENGTHS[:straight] + 3).to_sym}-high straight"
      when :three_of_a_kind
        r = largest_rank 3
        m = "trip #{ActiveSupport::Inflector.pluralize(r.to_sym.to_s)}"

        if length > 3
          cards = remaining_cards(r, 3)
          r1 = cards.largest_rank
          m += " with #{r1.to_sym}"

          if length > 4
            cards = cards.remaining_cards r1
            r2 = cards.largest_rank
            m += " and #{r2.to_sym}"
          end
        end
        m
      when :two_pair
        first_pair = largest_rank 2
        cards = remaining_cards first_pair, -1
        second_pair = cards.largest_rank 2

        m = "#{ActiveSupport::Inflector.pluralize(first_pair.to_sym.to_s)} and #{ActiveSupport::Inflector.pluralize(second_pair.to_sym.to_s)}"

        if length > 4
          cards = cards.remaining_cards second_pair, -1
          "#{m} with #{cards.largest_rank.to_sym} kicker"
        else
          m
        end
      when :one_pair
        pair = largest_rank 2

        m = "pair of #{ActiveSupport::Inflector.pluralize(pair.to_sym.to_s)}"

        if length > 2
          cards = remaining_cards pair, -1
          r1 = cards.largest_rank
          m += " with #{r1.to_sym}"

          if length > 3
            cards = cards.remaining_cards r1, -1
            r2 = cards.largest_rank

            if length > 4
              cards = cards.remaining_cards r2, -1
              r3 = cards.largest_rank
              m += ", #{r2.to_sym}, and #{r3.to_sym}"
            else
              m += " and #{r2.to_sym}"
            end
          end
        end
        m
      when :high_card
        cards = self
        hand = [5, length].min.times.inject([]) do |h, i|
          c = cards.largest_rank
          h << c.to_sym
          cards = cards.remaining_cards(c, -1)
          h
        end

        if length == 1
          "#{hand.first}"
        elsif length == 2
          "#{hand.first} and #{hand.last}"
        else
          "#{hand[0..-2].join(', ')}, and #{hand.last}"
        end
      end
    end

    def all_cards(suit)
      self.class().new(select { |c| c.suit == suit })
    end

    def remaining_cards(
      rank_of_cards_to_remove,
      number_of_cards_to_remove = 1
    )
      num_matched_cards = 0
      reduce(self.class().new([])) do |cards, c|
        if (
          c.rank == rank_of_cards_to_remove && (
            num_matched_cards < number_of_cards_to_remove ||
            number_of_cards_to_remove < 0
          )
        )
          num_matched_cards += 1
        else
          cards << c
        end
        cards
      end
    end

    def largest_rank(number_of_cards = 1, suits = Suit.all_suits)
      rank = -1
      each do |card|
        if (
          card.rank > rank &&
          suits.include?(card.suit) &&
          count { |c| c.rank == card.rank } >= number_of_cards &&
          card.rank > rank
        )
          rank = card.rank
        end
      end
      rank
    end

    private

    # @return [Array<Array<Symbol,Integer>>]
    def self.poker_hand_strengths_sorted_desc
      POKER_HAND_STRENGTHS.sort { |a, b| b.last <=> a.last }
    end
  end
end
