module Zabbirc
  module Irc
    module PluginMethods
      extend ActiveSupport::Concern
      include Help

      def help_command m, cmd
        cmd = HelpCommand.new(ops, m, cmd)
        cmd.run
      end

      def zabbirc_status m
        ops_msg = ops.find_all{|o| o.nick.present? }.collect{|o| "#{o.nick} as #{o.login}"}
        msg = []
        version = "Zabbirc #{Zabbirc::VERSION}"
        if Zabbix::Connection.test_connection
          msg << "#{m.user.nick}: #{version} - Zabbix API connection successfull"
        else
          msg << "#{m.user.nick}: #{version} - Zabbix API connection FAILED !!!"
        end
        msg << "#{m.user.nick}: Identified ops: #{ops_msg.join(", ")}"
        m.reply msg.join("\n")
      rescue Zabbix::NotConnected => e
        rescue_not_connected m, e
      end

      def acknowledge_event m, eventid, message
        op = authenticate m
        return unless op
        event = find_event m, eventid
        return unless event

        if event.acknowledge "#{op.nick}: #{message}"
          m.reply "#{op.nick}: Event `#{event.label}` acknowledged with message: #{message}"
        else
          m.reply "#{op.nick}: Could not acknowledge event `#{event.label}`"
        end
      rescue Zabbix::NotConnected => e
        rescue_not_connected m, e
      end

      def host_status m, host
        op = authenticate m
        return unless op
        host = find_host m, host
        return unless host

        triggers = Zabbix::Trigger.get(hostids: host.id, filter: {value: 1}, selectHosts: :extend)
        triggers = triggers.sort{|x,y| x.priority <=> y.priority }
        msg = ["#{op.nick}: Host: #{host.name}"]
        if triggers.empty?
          msg[0] << " - status: OK"
        else
          msg[0] << " - status: #{triggers.size} problems"
          triggers.each do |trigger|
            msg << "#{op.nick}: status: #{trigger.label}"
          end
        end
        m.reply msg.join("\n")
      rescue Zabbix::NotConnected => e
        rescue_not_connected m, e
      end

      def host_latest m, host, limit
        limit ||= 8
        op = authenticate m
        return unless op
        host = find_host m, host
        return unless host

        msg = ["#{op.nick}: Host: #{host.name}"]
        events = Zabbix::Event.get(hostids: host.id, limit: limit, selectHosts: :extend, selectRelatedObject: :extend, sortfield: :clock, sortorder: "DESC")
        if events.empty?
          msg[0] << " - no events found"
        else
          msg[0] << " - showing last #{events.size} events"
          events.each do |event|
            msg << "#{op.nick}: !latest: #{event.label}"
          end
        end
        m.reply msg.join("\n")
      rescue Zabbix::NotConnected => e
        rescue_not_connected m, e
      end

      def sync_ops m, u=nil
        return if u and u.nick == bot.nick
        bot.zabbirc_service.ops_service.iterate
      end

      ### Settings
      def settings_command m, cmd
        cmd = SettingsCommand.new(ops, m, cmd)
        cmd.run
      end

      ### Events
      def list_events m, priority=nil, host=nil
        op = authenticate m
        return unless op
        priority = parse_priority(m, priority || 0)
        return unless priority
        
        events = Zabbix::Event.recent
        events = events.select{|e| e.priority >= priority }
        events = events.select{|e| e.any_host_matches? /#{host}/ } if host
        msg = if events.any?
                events.collect do |e|
                  "#{op.nick}: #{e.label}"
                end.join("\n")
              else
                host_filter = host ? " and host `#{host}`" : ""
                "#{op.nick}: No last events for priority `#{priority}`#{host_filter}"
              end
        m.reply msg
      rescue Zabbix::NotConnected => e
        rescue_not_connected m, e
      end

      def ops
        @ops ||= bot.zabbirc_service.ops
      end

      ### Authentication and helpers

      def get_op obj
        login = get_login obj
        ops.get login
      end

      alias_method :authenticate, :get_op

      def get_login obj
        case obj
        when Cinch::Message
          obj.user.user.sub("~","")
        when Cinch::User
          obj.user.user.sub("~","")
        when String
          obj
        end
      end

      private

      def find_host m, host
        op = get_op m
        hosts = Zabbix::Host.get(search: {host: host})
        case hosts.size
        when 0
          m.reply "#{op.nick}: Host not found `#{host}`"
        when 1
          return hosts.first
        when 2..10
          m.reply "#{op.nick}: Found #{hosts.size} hosts: #{hosts.collect(&:name).join(', ')}. Be more specific"
        else
          m.reply "#{op.nick}: Found #{hosts.size} Be more specific"
        end
        false
      end

      def find_event m, short_eventid
        op = get_op m
        begin
          eventid = Zabbirc.events_id_shortener.get_id short_eventid
          unless eventid
            m.reply "#{op.nick}: Bad event id `#{short_eventid}`"
            return false
          end
          event = Zabbix::Event.find(eventid, {selectHosts: :extend, selectRelatedObject: :extend})
          if event.nil?
            m.reply "#{op.nick} Could not find event with id `#{short_eventid}`"
            return false
          end
          event
        rescue Zabbix::IDNotUniqueError => e
          m.reply "#{op.nick} Could not find event: #{e}"
          false
        end
      end

      def parse_priority m, priority
        op = get_op m
        Priority.new(priority)
      rescue ArgumentError => e
        m.reply("#{op.nick}: #{e}")
        nil
      end

      def rescue_not_connected m, e
        op = get_op m
        return unless op
        m.reply "#{op.nick}: #{e.to_s}"
      end
    end
  end
end