module ZabbixIrcBot
  module Zabbix
    class Trigger < Resource
      def self.find id
        res = api.trigger.get triggerids: id
        if res.size == 0
          nil
        elsif res.size > 1
          raise StandardError, "Trigger ID is not unique"
        else
          self.new res.first
        end
      end

      def initialize attrs
        @attrs = ActiveSupport::HashWithIndifferentAccess.new attrs
        raise AttributeError, "attribute `triggerid` not found, propably not an Event" unless @attrs.key? :triggerid
      end
    end
  end
end
