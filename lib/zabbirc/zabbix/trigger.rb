module Zabbirc
  module Zabbix
    class Trigger < Resource::Base
      has_many :hosts

      def priority
        Priority.new(super.to_i)
      end

      def value
        case @attrs[:value].to_i
        when 0
          :ok
        when 1
          :problem
        else
          @attrs[:value]
        end
      end

      def message
        if description.include?("{HOST.NAME}")
          description.sub("{HOST.NAME}", hosts.collect(&:host).join(', '))
        else
          "#{description} on #{hosts.collect(&:host).join(', ')}"
        end
      end

      def label
        format_label "%time [%priority-code] %msg - %value"
      end

      def changed_at
        Time.at(lastchange.to_i)
      end

      def format_label fmt
        fmt.gsub("%priority-code", "#{priority.code}").
            gsub("%priority-num", "#{priority.number}").
            gsub("%time", "#{changed_at.to_formatted_s(:short)}").
            gsub("%msg", "#{message}").
            gsub("%id", "#{id}").
            gsub("%value", "#{value}")
      end
    end
  end
end
