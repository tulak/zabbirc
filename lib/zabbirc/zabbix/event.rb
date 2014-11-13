module Zabbirc
  module Zabbix
    class Event < Resource::Base
      has_many :hosts

      def self.recent options={}
        params = {
            acknowledged: false,
            time_from: Zabbirc.config.notify_about_events_from_last.ago.utc.to_i,
            priority_from: 0,
            selectRelatedObject: :extend,
            selectHosts: :extend
        }.merge(options)

        priority_from = Priority.new(params.delete(:priority_from))
        events = get params
        events = events.find_all{|e| e.priority >= priority_from }
        events.sort{|x,y| x.priority <=> y.priority }
      end

      attr_reader :attrs

      delegate :priority, :priority_code, to: :related_object

      def related_object
        raise AttributeError, "`source` attribute required" if @attrs[:source].blank?
        raise AttributeError, "`object` attribute required" if @attrs[:object].blank?
        @related_object ||= determine_related_object
      end

      def acknowledged?
        acknowledged.to_i == 1
      end

      def created_at
        Time.at(clock.to_i)
      end

      def value
        case @attrs[:source].to_i
        when 0
          case @attrs[:value].to_i
          when 0
            :ok
          when 1
            :problem
          end
        else
          @attrs[:value]
        end
      end

      alias_method :state, :value

      def message
        desc = related_object.description
        if desc.include?("{HOST.NAME}")
          desc.sub("{HOST.NAME}", hosts.collect(&:host).join(', '))
        else
          "#{desc} on #{hosts.collect(&:host).join(', ')}"
        end
      end

      def label
        format_label "|%id| %time [%priority-code] %msg - %state"
      end

      def format_label fmt
        fmt.gsub("%priority-code", "#{priority.code}").
            gsub("%priority-num", "#{priority.number}").
            gsub("%time", "#{created_at.to_formatted_s(:short)}").
            gsub("%msg", "#{message}").
            gsub("%id", "#{id}").
            gsub("%state", "#{state}")
      end

      private

      def determine_related_object
        case @attrs[:object].to_i
        when 0
          @attrs[:relatedObject] ? Trigger.new(@attrs[:relatedObject]) : Trigger.find(@attrs[:objectid])
        else
          raise StandardError, "related object #{@attrs[:object].to_i} not implemented yet"
        end
      end
    end
  end
end