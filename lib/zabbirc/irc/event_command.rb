module Zabbirc
  module Irc
    class EventCommand < BaseCommand
      register_help "events", "Show events from last #{Zabbirc.config.notify_about_events_from_last.to_i / 60} minutes filtered by <priority> and <host>. Usage: !events [<priority [<host>]]"
      register_help "ack", "Acknowledges event with message. Usage: !ack <event-id> <ack-message>"
      private
      def perform
        command = @args.shift
        case command
        when "events"
          perform_events
        when "ack"
          perform_ack
        end
      end

      def perform_events
        priority = parse_priority(@args.shift || 0)
        return unless priority
        host = @args.join(" ")

        events = Zabbix::Event.recent
        events = events.select{|e| e.priority >= priority }
        events = events.select{|e| e.any_host_matches? /#{host}/i } if host.present?
        msg = if events.any?
                events.collect do |e|
                  "#{e.label}"
                end
              else
                host_filter = host.present? ? " and host `#{host}`" : ""
                "No last events for priority `#{priority}`#{host_filter}"
              end
        reply msg
      end

      def perform_ack
        short_event_id = @args.shift
        message = @args.join(" ")

        if short_event_id.blank? or message.blank?
          reply help_features["ack"]
          return
        end
        event = find_event short_event_id
        return unless event

        if event.acknowledge "#{op.nick}: #{message}"
          reply "Event `#{event.label}` acknowledged with message: #{message}"
        else
          reply "Could not acknowledge event `#{event.label}`"
        end
      end

      def find_event short_eventid
        eventid = Zabbirc.events_id_shortener.get_id short_eventid
        unless eventid
          reply "Bad event id `#{short_eventid}`"
          return false
        end
        event = Zabbix::Event.find(eventid, {selectHosts: :extend, selectRelatedObject: :extend})
        if event.nil?
          reply "Could not find event with id `#{short_eventid}`"
          return false
        end
        event
      rescue Zabbix::IDNotUniqueError => e
        reply "Could not find event: #{e}"
        false
      end
    end
  end
end
