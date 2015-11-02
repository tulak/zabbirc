module Zabbirc
  module Irc
    class HostCommand < BaseCommand
      register_help "status", "Show status of host. Usage: !status <hostname>"
      register_help "latest", "Show last <N> (default 8) events of host. Usage: !latest <hostname> [<N>]"
      private
      def perform
        @sub_command = @args.shift
        case @sub_command
        when "status"
          perform_status
        when "latest"
          perform_latest
        end
      end

      def host
        @host ||= begin
          hostname = @args.shift
          if hostname.blank?
            reply help_features[@sub_command]
            return
          end
          find_host hostname
        end
      end

      def perform_status
        return unless host

        triggers = Zabbix::Trigger.get(hostids: host.id, filter: {value: 1}, selectHosts: :extend)
        triggers = triggers.sort{|x,y| x.priority <=> y.priority }
        msg = ["Host: #{host.name}"]
        if triggers.empty?
          msg[0] << " - status: OK"
        else
          msg[0] << " - status: #{triggers.size} problems"
          triggers.each do |trigger|
            msg << "status: #{trigger.label}"
          end
        end
        reply msg
      end

      def perform_latest
        return unless host
        limit = @args.shift
        limit ||= 8

        msg = ["Host: #{host.name}"]
        events = Zabbix::Event.get(hostids: host.id, limit: limit, selectHosts: :extend, selectRelatedObject: :extend, sortfield: :clock, sortorder: "DESC")
        if events.empty?
          msg[0] << " - no events found"
        else
          msg[0] << " - showing last #{events.size} events"
          events.each do |event|
            msg << "!latest: #{event.label}"
          end
        end
        reply msg
      end

    end
  end
end
