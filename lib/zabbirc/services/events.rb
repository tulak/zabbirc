module Zabbirc
  module Services
    class Events < Base
      def iterate
        synchronize do
          recent_events = Zabbix::Event.recent

          recent_events.each do |event|
            @service.ops.interested_in(event).notify event
          end
        end
      end

      private

      def send_notifications op, events
        events.each do |event|
          op.notify event
        end
      end
    end
  end
end