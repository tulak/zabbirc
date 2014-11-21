module Zabbirc
  class OpList
    include Enumerable

    def initialize ops=nil
      @ops = {}
      if ops
        ops.each do |op|
          add op
        end
      end
    end

    def authenticate name
      @ops.key? name
    end

    alias_method :exists?, :authenticate

    def get name
      @ops[name]
    end

    def add op
      if exists? op.login
        return get(op.login)
      end
      @ops[op.login] = op
    end

    def each &block
      @ops.values.each &block
    end

    def interested_in event
      self.class.new(find_all{ |op| op.interested_in? event })
    end

    def notify event
      group_by(&:primary_channel).each do |channel, ops|
        op_targets = ops.collect{|op| "#{op.nick}:" }.join(" ")
        channel.send "#{op_targets} #{event.label}"
        ops.each{ |op| op.event_notified event }
      end
    end
  end
end