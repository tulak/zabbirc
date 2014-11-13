module Zabbirc
  module Irc
    module PluginMethods

      def host_status m, host
        return unless authenticate m.user.nick
        op = get_op m
        hosts = Zabbix::Host.get(search: {host: host})
        case hosts.size
        when 1
          host = hosts.first
          triggers = Zabbix::Trigger.get(hostids: host.id, filter: {value: 1}, selectHosts: :extend)
          triggers = triggers.sort{|x,y| x.priority <=> y.priority }
          msg = ["#{op.nick}: Host: #{host.name}"]
          triggers.each do |trigger|
            msg << "#{op.nick}: #{trigger.label}"
          end
          m.reply msg.join("\n")
        when 2..10
          m.reply "#{op.nick}: Found #{hosts.size} hosts: #{hosts.collect(&:name).join(', ')}. Be more specific"
        else
          m.reply "#{op.nick}: Found #{hosts.size} Be more specific"
        end
      end

      def sync_ops m, u=nil
        return if u and u.nick == bot.nick
        bot.zabbirc_service.ops_service.iterate
      end

      ### Settings
      def show_settings m
        return unless authenticate m.user.nick
        op = get_op m
        m.reply "#{op.nick}: #{op.setting}"
      end

      def set_setting m, key, _rest, value
        return unless authenticate m.user.nick
        op = get_op m
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
        # binding.pry
        return unless authenticate m.user.nick
        events = Zabbix::Event.recent
        msg = if events.any?
                events.collect do |e|
                  "#{m.user.nick}: #{e.label}"
                end.join("\n")
              else
                "#{m.user.nick}: No last events"
              end
        m.reply msg
      end

      def ops
        @ops ||= bot.zabbirc_service.ops
      end

      ### Authentication and helpers
      def authenticate obj
        nick = get_nick obj
        ops.authenticate nick
      end

      def get_op obj
        nick = get_nick obj
        ops.get nick
      end

      def get_nick obj
        case obj
        when Cinch::Message
          obj.user.nick
        when Cinch::User
          obj.nick
        when String
          obj
        end
      end

    end
  end
end