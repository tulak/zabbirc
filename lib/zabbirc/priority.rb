module Zabbirc
  class Priority
    include Comparable

    PRIORITIES = {
        0 => :not_classified,
        1 => :information,
        2 => :warning,
        3 => :average,
        4 => :high,
        5 => :disaster
    }

    attr_reader :number, :code
    def initialize priority
      case priority
      when String, Symbol
        raise ArgumentError, "unknown priority `#{priority}`" unless PRIORITIES.key(priority.to_sym)
        @number = PRIORITIES.key(priority.to_sym)
        @code = priority.to_sym
      when Integer
        raise ArgumentError, "unknown priority `#{priority}`" unless PRIORITIES[priority]
        @number = priority
        @code = PRIORITIES[@number]
      else
        raise ArgumentError, "cannot create priority from `#{priority}` of class `#{priority.class}`"
      end
    end

    def <=> other
      number <=> other.number
    end

    def to_s
      code.to_s
    end
  end
end