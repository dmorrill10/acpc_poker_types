
# Local mixins
require File.expand_path('../../mixins/easy_exceptions', __FILE__)

# Programmatic representation of a stack of chips.
class ChipStack
   include Comparable
   
   exceptions :illegal_number_of_chips
      
   # @param [#to_i] number_of_chips The number of chips to be made into a stack.
   # @raise (see #assert_valid_number_of_chips)
   def initialize(number_of_chips=0)
      assert_valid_number_of_chips number_of_chips.to_i
      @value = number_of_chips.to_i
   end
   
   # @see Integer#to_s
   def to_s(base=10)
      @value.to_s base
   end
   
   # @return [Integer] The number of chips to be made into a stack (must be a whole number).
   def to_i
      @value
   end
   
   # Combines this stack with a number of chips, +number_of_chips+.
   # @param [#to_i] number_of_chips The number of chips to with which this stack will be combined.
   # @return [ChipStack] The chip stack that results from adding +number_of_chips+ chips to this stack.
   # @raise (see ChipStack#initialize)
   def +(number_of_chips)
      ChipStack.new @value + number_of_chips.to_i
   end
   
   # Takes a +number_of_chips+ from this stack.
   # @param [#to_i] number_of_chips The number of chips to be taken.
   # @return [ChipStack] The chip stack that results from removing +number_of_chips+ chips from this stack.
   # @raise (see ChipStack#initialize)
   def -(number_of_chips)
      ChipStack.new @value - number_of_chips.to_i
   end
   
   # @param [#to_i] other The other operand.
   # @return [Array<ChipStack>, Array<Integer>] List where the first element is a +ChipStack+ version of the +other+ operand and the second element is this instance.
   #  If there was a problem converting the +other+ operand to a +ChipStack+, the returned array will contain the +Integer+ versions of +other+ and +self+.
   def coerce(other)
      begin
         [ChipStack.new(other.to_i), self]
      rescue
         [other.to_i, to_i]
      end
   end
   
   # Tests whether or not this stack is larger than another stack or a number.
   # @param [#to_i] other The other operand.
   # @return [Boolean] +true+ 
   def <=>(other)
      if @value < other.to_i
         -1
      elsif @value > other.to_i
         1
      else
         0
      end
   end
   
   private
   
   # @param [Integer] number_of_chips A number of chips.
   # @raise IllegalNumberOfChips
   def assert_valid_number_of_chips(number_of_chips)
      raise IllegalNumberOfChips if number_of_chips < 0 or number_of_chips.round != number_of_chips
   end
end
