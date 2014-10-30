module Zabbirc
  module Services
    class Events < Base
      def iterate
        synchronize do
          recen_events = Zabbix::Event.recent
          @service.ops.each do |nick, op|
            send_notifications op, recen_events
          end if recen_events.any?
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