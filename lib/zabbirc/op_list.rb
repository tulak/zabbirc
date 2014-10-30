module Zabbirc
  class OpList
    include Enumerable

    def initialize
      @ops = {}
    end

    def authenticate name
      @ops.key? name
    end

    alias_method :exists?, :authenticate

    def get name
      @ops[name]
    end

    def add op
      if exists? op.nick
        return get(op.nick)
      end
      @ops[op.nick] = op
    end

    def each &block
      @ops.values.each &block
    end
  end
end