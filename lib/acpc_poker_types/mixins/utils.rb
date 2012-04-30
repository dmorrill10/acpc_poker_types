
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
