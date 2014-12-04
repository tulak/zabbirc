module Zabbirc
  module Irc
    module PluginMethods
      extend ActiveSupport::Concern
      include Help
      extend Help::ClassMethods

      def zabbirc_status m
        ops_msg = ops.find_all{|o| o.nick.present? }.collect{|o| "#{o.nick} as #{o.login}"}
        msg = []
        if Zabbix::Connection.test_connection
          msg << "#{m.user.nick}: Zabbix API connection successfull"
        else
          msg << "#{m.user.nick}: Zabbix API connection FAILED !!!"
        end
        msg << "#{m.user.nick}: Identified ops: #{ops_msg.join(", ")}"
        m.reply msg.join("\n")
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
      end

      def sync_ops m, u=nil
        return if u and u.nick == bot.nick
        bot.zabbirc_service.ops_service.iterate
      end

      ### Settings
      def show_settings m
        op = authenticate m
        return unless op
        m.reply "#{op.nick}: #{op.setting}"
      end

      def set_setting m, key, value
        op = authenticate m
        return unless op
        case key
        when "notify"
          set_notify m, op, value
        when "events_priority"
          set_events_priority m, op, value
        when "primary_channel"
          set_primary_channel m, op, value
        else
          m.reply "#{op.nick}: unknown setting `#{key}`"
        end
      end

      def set_notify m, op, value
        if value.nil?
          m.reply "#{op.nick}: notify allowed values: true, on, 1, false, off, 0"
          return
        end
        case value
        when "true", "on", "1"
          op.setting.set :notify, true
        when "false", "off", "0"
          op.setting.set :notify, false
        else
          m.reply "#{op.nick}: uknown value `#{value}`. Allowed values: true, on, 1, false, off, 0"
          return
        end
        m.reply "#{op.nick}: setting `notify` was set to `#{op.setting.get :notify}`"
      end

      def set_events_priority m, op, value
        if value.nil?
          m.reply "#{op.nick}: events_priority allowed values: #{Priority::PRIORITIES.values.collect{|v| "`#{v}`"}.join(', ')} or numeric #{Priority::PRIORITIES.keys.join(", ")} "
          return
        end
        begin
          value = value.to_i if value =~ /^\d+$/
          priority = Priority.new value
        rescue ArgumentError
          m.reply "#{op.nick}: uknown value `#{value}`. Allowed values: #{Priority::PRIORITIES.values.collect{|v| "`#{v}`"}.join(', ')} or numeric #{Priority::PRIORITIES.keys.join(", ")} "
          return
        end
        op.setting.set :events_priority, priority.code
        m.reply "#{op.nick}: setting `events_priority` was set to `#{op.setting.get :events_priority}`"
      end

      def set_primary_channel m, op, value
        channel_names = op.channels.collect(&:name)
        if value.nil?
          m.reply "#{op.nick}: notify allowed values: #{channel_names.join(", ")}"
          return
        end
        case value
        when *channel_names
          op.setting.set :primary_channel, value
        else
          m.reply "#{op.nick}: uknown value `#{value}`. Allowed values: #{channel_names.join(", ")}"
          return
        end
        m.reply "#{op.nick}: setting `primary_channel` was set to `#{op.setting.get :primary_channel}`"
      end

      ### Events
      def list_events m
        op = authenticate m
        return unless op
        events = Zabbix::Event.recent
        msg = if events.any?
                events.collect do |e|
                  "#{op.nick}: #{e.label}"
                end.join("\n")
              else
                "#{op.nick}: No last events"
              end
        m.reply msg
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

      def find_event m, eventid
        op = get_op m
        begin
          event = Zabbix::Event.find(eventid, {selectHosts: :extend, selectRelatedObject: :extend})
          if event.nil?
            m.reply "#{op.nick} Could not find event with id `#{eventid}`"
            return false
          end
          event
        rescue Zabbix::IDNotUniqueError => e
          m.reply "#{op.nick} Could not find event: #{e}"
          false
        end
      end
    end
  end
end