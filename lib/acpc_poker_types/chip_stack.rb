
require 'dmorrill10-utils/class'

require 'delegate'

class AcpcPokerTypes::ChipStack < DelegateClass(Rational)
  exceptions :illegal_number_of_chips

  # @param [#to_i] number_of_chips The number of chips to be made into a stack.
  # @raise (see #assert_valid_value)
  def initialize(number_of_chips=0)
    @value = number_of_chips.to_i

    assert_valid_value

    super @value
  end

  def receive!(number_of_chips)
    @value += number_of_chips

    assert_valid_value

    __setobj__ @value

    self
  end
  def give!(number_of_chips)
    receive!(-number_of_chips)
  end

  private

  # @raise IllegalNumberOfChips
  def assert_valid_value
    raise IllegalNumberOfChips if @value < 0
  end
end
