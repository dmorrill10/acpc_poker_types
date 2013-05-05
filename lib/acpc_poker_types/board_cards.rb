require 'acpc_poker_types/pile_of_cards'

# List of community board cards.
class AcpcPokerTypes::BoardCards < Array
  def initialize(board_cards=[[]])
    super(board_cards.map { |elem| AcpcPokerTypes::PileOfCards.new elem })
  end

  def round
    self.length - 1
  end

  alias_method :array_push, :push

  def next_round!
    self.array_push AcpcPokerTypes::PileOfCards.new
    self
  end

  def push(new_element)
    self.last.push new_element
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
