
require 'dmorrill10-utils'

require File.expand_path('../pile_of_cards', __FILE__)

# List of community board cards.
class BoardCards < PileOfCards

  exceptions :too_many_board_cards

  attr_reader :round

  def initialize() next_round! end

  def next_round!
    @round = if @round then @round + 1 else 0 end
    self[@round] = PileOfCards.new
    self
  end

  def push(new_element)
    self[@round].push new_element
    self
  end

  alias_method :<<, :push

  # @return [String] The string representation of these board cards.
  def to_str
    return '' if inject(true) do |no_board_cards_shown, pile_for_round|
      no_board_cards_shown &= pile_for_round.empty?
    end
    '/' + (map { |pile_for_round| pile_for_round.join }).join('/')
  end

  # @see #to_str
  alias_method :to_s, :to_str
end
