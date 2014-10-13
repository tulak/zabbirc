module ZabbixIrcBot
  module Zabbix
    class Event < Resource
      def self.recent include_related_object: false, include_hosts: false
        params = {
            acknowledged: false,
            time_from: ZabbixIrcBot.config.notify_about_avents_older_than.ago.utc.to_i
        }

        params[:selectHosts] = :extend if include_hosts
        params[:selectRelatedObject] = :extend if include_related_object

        res = api.event.get params
        res.collect do |e|
          Event.new(e)
        end
      end

      attr_reader :attrs

      def initialize attrs
        @attrs = ActiveSupport::HashWithIndifferentAccess.new attrs
        raise AttributeError, "attribute `eventid` not found, propably not an Event" unless @attrs.key? :eventid
      end

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

      private

      def determine_related_object
        case @attrs[:object].to_i
        when 0
          @attrs[:relatedObject] ? Trigger.new(@attrs[:relatedObject]) : Trigger.find(@attrs[:objectid])
        end
      end

    end
  end
end