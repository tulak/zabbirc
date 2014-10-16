module ZabbixIrcBot
  module Zabbix
    class Trigger < Resource::Base
      PRIORITIES = {
          0 => :not_classified,
          1 => :information,
          2 => :warning,
          3 => :average,
          4 => :high,
          5 => :disaster
      }
      has_many :hosts

      def priority
        super.to_i
      end

      def priority_code
        PRIORITIES[priority]
      end
    end
  end
end
