
require 'dmorrill10-utils/class'

require 'acpc_poker_types/pile_of_cards'

# List of community board cards.
class AcpcPokerTypes::BoardCards < AcpcPokerTypes::PileOfCards

  exceptions :too_many_board_cards

  attr_reader :round

  def initialize() @round = nil; next_round! end

  def next_round!
    @round = if @round then @round + 1 else 0 end
    self[@round] = AcpcPokerTypes::PileOfCards.new
    self
  end

  def push(new_element)
    self[@round].push new_element
    self
  end

  alias_method :<<, :push

  # @return [String] The string representation of these board cards.
  def to_s
    if all? { |pile_for_round| pile_for_round.empty? }
      ''
    else
      '/' + (map { |pile_for_round| pile_for_round.join }).join('/')
    end
  end

  # @see #to_s
  alias_method :to_str, :to_s

  # @return [String] The string representation of these board cards.
  def to_acpc
    if all? { |pile_for_round| pile_for_round.empty? }
      ''
    else
      '/' + (map do |pile_for_round|
        (pile_for_round.map { |card| card.to_acpc }).join
      end).join('/')
    end
  end
end
