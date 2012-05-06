
module StringFormManipulation
   # @return This string in camel-case class name form.
   def to_camel_case
      class_name = to_s.capitalize
      class_name.gsub(/[_\s]+./) { |match| match = match[1,].capitalize }
   end
   
   alias_method :to_class_name, :to_camel_case
end

class String
   include StringFormManipulation
end

class Symbol
   include StringFormManipulation
end

class Class   
   private

   # @param [Array] names A list of exception names that the calling class would
   #  like to define.
   def exceptions(*names)
      names.each do |name|
         error_name = name.to_class_name
         const_set(error_name, Class.new(RuntimeError))
      end
   end
   
   def alias_new(alias_of_new)
      alias_class_method alias_of_new, :new
   end
   
   # @param [#to_sym] alias_method A class method to alias the class method, +method_to_alias+.
   # @param [#to_sym] method_to_alias A class method to be aliased by +alias_method+.
   def alias_class_method(alias_method, method_to_alias)
      singleton_class.alias_method_in_singleton_context alias_method.to_sym, method_to_alias.to_sym
   end
   
   # Must do this operation in singleton context
   class << self
      def alias_method_in_singleton_context(alias_method, method_to_alias)
         alias_method alias_method, method_to_alias
      end
   end
end

module Enumerable
   
   # @return [Integer] Sum of the elements in this instance. All elements must
   #  have a +to_i+ method, which converts the element into a form that may be
   #  summed with an +Integer+.
   def sum
      flatten.inject(0){ |sum, element_amount| sum += element_amount.to_i }
   end
   
   # @return [Array] The array resulting from summing all elements in
   #  this instance. All elements must have a +sum+ or +to_i+ method.
   def mapped_sum
      map { |element| if element.respond_to? :sum then element.sum else element.to_i end }
   end
end


########### Table game specific ##########
class Integer
   
   exceptions :seat_out_of_bounds, :relative_position_out_of_bounds
   
   # @param [Integer] seat The seat to which the relative position is desired.
   # @param [Integer] number_of_players The number of players at the table.
   # @return [Integer] The relative position of +self+ to +seat+, given the
   #  number of players at the table, +number_of_players+, indexed such that
   #  the seat immediately to the left of +seat+ has a +position_relative_to+ of
   #  zero.
   # @example <code>1.position_relative_to 0, 3</code> == 0
   # @example <code>1.position_relative_to 1, 3</code> == 2
   def position_relative_to(seat, number_of_players)
      raise SeatOutOfBounds unless seat_in_bounds?(seat, number_of_players) &&
         seat_in_bounds?(self, number_of_players)
         
      adjusted_seat = if self > seat
         self
      else
         self + number_of_players
      end
      adjusted_seat - seat - 1
   end
   
   # Inverse operation of +position_relative_to+.
   # Given
   #  <code>relative_position = seat.position_relative_to to_seat, number_of_players</code>
   # then
   #  <code>to_seat = seat.seat_from_relative_position relative_position, number_of_players</code>
   #
   # @param [Integer] relative_position_of_self_to_result The relative position
   #  of seat +self+ to the seat that is returned by this function.
   # @param [Integer] number_of_players The number of players at the table.
   # @return [Integer] The seat to which the relative position,
   #  +relative_position_of_self_to_result+, of +self+ was derived, given the
   #  number of players at the table, +number_of_players+, indexed such that
   #  the seat immediately to the left of +from_seat+ has a
   #  +position_relative_to+ of zero.
   # @example <code>1.seat_from_relative_position 0, 3</code> == 0
   # @example <code>1.seat_from_relative_position 2, 3</code> == 1
   def seat_from_relative_position(relative_position_of_self_to_result,
                                   number_of_players)
      raise SeatOutOfBounds unless seat_in_bounds?(self, number_of_players)
      raise RelativePositionOutOfBounds unless seat_in_bounds?(relative_position_of_self_to_result,
                                                               number_of_players)
         
      position_adjustment = relative_position_of_self_to_result + 1
      
      to_seat = self + number_of_players - position_adjustment
      if self > to_seat || !seat_in_bounds?(to_seat, number_of_players)
         self - position_adjustment
      else
         to_seat
      end
   end
   
   private
   
   def seat_in_bounds?(seat, number_of_players)
      seat < number_of_players && seat >= 0
   end
end
