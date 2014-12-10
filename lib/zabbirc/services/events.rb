module Zabbirc
  module Services
    class Events < Base
      def iterate
        synchronize do
          recent_events = Zabbix::Event.recent
          recent_events = filter_out_repeated_events(recent_events)

          recent_events.each do |event|
            @service.ops.interested_in(event).notify event
          end
        end
      rescue Zabbix::NotConnected => e
        if Zabbix::Connection.up?
          @service.ops.interested.notify e.to_s
          Zabbix::Connection.down!
        end
      end

      private

      def filter_out_repeated_events events
        triggers = events.group_by{|e| e.related_object.id }
        triggers.collect do |_id, events|
          events.sort_by{|e| e.created_at }.last
        end
      end
    end
  end
end