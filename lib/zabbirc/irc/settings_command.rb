module Zabbirc
  module Irc
    class SettingsCommand < BaseCommand
      register_help "settings", "Manage your op specific settings. Usage: !settings [show | set]"
      register_help "settings set", [
          "Set your op specific settings. Usage: !setting set <setting-name> <setting-value> [hostgroup <host-group-name> | hostgroup-all]",
          "Some settings can be set per hostgroup. Flag `hostgroup-all` means that it will rewrite setting for all hostgroups.",
          "When used without optional part(hostgroup), it will change default settings."
      ]

      private
      def perform
        sub_cmd = @args.shift
        case sub_cmd
        when nil, "show"
          show
        when "set"
          set
        else
          reply "unknown command `#{sub_cmd}`"
        end
      end

      def show
        reply "#{@op.setting}"
      end

      def set
        key = @args.shift
        case key
        when "notify", "notify_recoveries"
          set_boolean key
        when "events_priority"
          set_events_priority
        when "primary_channel"
          set_primary_channel
        when nil, ""
          reply help_features["settings set"]
        else
          reply "unknown setting `#{key}`"
        end
      end

      def set_boolean key
        value = @args.shift
        if value.nil?
          reply "#{key} allowed values: true, on, 1, false, off, 0"
          return
        end

        case value
        when "true", "on", "1"
          @op.setting.set key, true
        when "false", "off", "0"
          @op.setting.set key, false
        else
          reply "uknown value `#{value}`. Allowed values: true, on, 1, false, off, 0"
          return
        end
        reply "setting `#{key}` has been set to `#{@op.setting.get key}`"
      end

      def set_events_priority
        value = @args.shift
        if value.nil?
          reply "events_priority allowed values: #{Priority::PRIORITIES.values.collect{|v| "`#{v}`"}.join(', ')} or numeric #{Priority::PRIORITIES.keys.join(", ")} "
          return
        end
        begin
          value = value.to_i if value =~ /^\d+$/
          priority = Priority.new value
        rescue ArgumentError
          reply "uknown value `#{value}`. Allowed values: #{Priority::PRIORITIES.values.collect{|v| "`#{v}`"}.join(', ')} or numeric #{Priority::PRIORITIES.keys.join(", ")} "
          return
        end
        @op.setting.set :events_priority, priority.code
        reply "setting `events_priority` has been set to `#{@op.setting.get :events_priority}`"
      end

      def set_primary_channel
        channel_names = @op.channels.collect(&:name)
        value = @args.shift
        if value.nil?
          reply "notify allowed values: #{channel_names.join(", ")}"
          return
        end
        case value
        when *channel_names
          @op.setting.set :primary_channel, value
        else
          reply "uknown value `#{value}`. Allowed values: #{channel_names.join(", ")}"
          return
        end
        reply "setting `primary_channel` has been set to `#{@op.setting.get :primary_channel}`"
      end

    end
  end
end
