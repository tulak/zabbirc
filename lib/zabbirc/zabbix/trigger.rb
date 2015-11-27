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

      def state
        case value
        when :ok then "$C,GREEN$ok$C,RST$"
        when :problem then "$C,RED$problem$C,RST$"
        else
          value
        end
      end

      def message
        host_label_regexp = Regexp.union("{HOSTNAME}", "{HOST.NAME}")
        host_names = "$U$#{hosts.collect(&:host).join(', ')}$U,RST$"
        if description =~ host_label_regexp
          description.sub(host_label_regexp, host_names)
        else
          "#{description} on #{host_names}"
        end
      end



      def severity_label
        code = priority.code
        case code
        when :not_classified then "$C,GREY$[#{code}]$C,RST$"
        when :information    then "$C,LIGHT_GREEN$[#{code}]$C,RST$"
        when :warning        then "$C,YELLOW$[#{code}]$C,RST$"
        when :average        then "$C,ORANGE$[#{code}]$C,RST$"
        when :high           then "$C,RED$[#{code}]$C,RST$"
        when :disaster       then "$C,BROWN$[#{code}]$C,RST$"
        end
      end

      def label
        format_label "%time %severity %msg - %value"
      end

      def changed_at
        Time.at(lastchange.to_i)
      end

      def format_label fmt
        fmt.gsub("%priority-code", "#{priority.code}").
            gsub("%priority-num", "#{priority.number}").
            gsub("%severity", "#{severity_label}").
            gsub("%time", "#{changed_at.to_formatted_s(:short)}").
            gsub("%msg", "#{message}").
            gsub("%id", "#{id}").
            gsub("%value", "#{state}")
      end
    end
  end
end
