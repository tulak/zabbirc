module Zabbirc
  module Irc
    class SettingsCommand < BaseCommand
      register_help "settings", "Manage your op specific settings. Usage: !settings [show | set]"
      register_help "settings set", [
          "Set your op specific settings. Usage: !setting set <setting-name> <setting-value> [hostgroups <host-group-name>[,<host-group-name>] | hostgroups-all]",
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
          reply "settings: unknown command `#{sub_cmd}`"
          reply help_features["settings"], prefix: "HELP settings: "
        end
      end

      def show
        inline = @op.setting.collect do |key, value|
          next if key == "host_groups"
          "$C,BLUE_CYAN$#{key}:$C,RST$ #{value}"
        end.compact.join(", ")

        reply "$C,GREY$Default settings: $C,RST$#{inline}"

        host_group_options = []
        @op.setting.get(:host_groups).each do |group_id, options|
          if options.any?
            group = Zabbix::HostGroup.find(group_id)
            group_options = options.collect{|k,v| "$C,BLUE_CYAN$#{k}:$C,RST$ #{v}" }.sort.join(", ")
            host_group_options << " - $C,ORANGE$#{group.name}: $C,RST$ #{group_options}"
          end
        end

        if host_group_options.any?
          reply "$C,GREY$Host group settings: $C,RST$"
          reply host_group_options
        end
      end

      def set
        key, value, host_groups_flag, host_groups  = parse_set_command
        case key
        when "notify", "notify_recoveries"
          value = validate_boolean key, value
        when "events_priority"
          value = validate_events_priority value
        when "primary_channel"
          value = validate_primary_channel value
        when nil, ""
          reply help_features["settings set"]
        else
          reply "unknown setting `#{key}`"
        end

        set_value key, value, host_groups_flag, host_groups
      end

      def validate_boolean key, value
        raise UserInputError, "#{key} allowed values: true, on, 1, false, off, 0" if value.blank?

        case value
        when "true", "on", "1" then true
        when "false", "off", "0" then false
        else
          raise UserInputError, "uknown value `#{value}`. Allowed values: true, on, 1, false, off, 0"
        end
      end

      def validate_events_priority value
        allowed_values = "#{Priority::PRIORITIES.values.collect{|v| "`#{v}`"}.join(', ')} or numeric #{Priority::PRIORITIES.keys.join(", ")} "
        raise UserInputError, "events_priority allowed values: #{allowed_values}" if value.blank?
        begin
          value = value.to_i if value =~ /^\d+$/
          priority = Priority.new value
        rescue ArgumentError
          raise UserInputError, "uknown value `#{value}`. Allowed values: #{allowed_values}"
        end
        priority.code
      end

      def validate_primary_channel value
        channel_names = @op.channels.collect(&:name)
        raise UserInputError, "primary_channel allowed values: #{channel_names.join(", ")}" if value.blank?
        raise UserInputError, "uknown value `#{value}`. Allowed values: #{channel_names.join(", ")}" unless channel_names.include? value
        value
      end

      def set_value key, value, host_groups_flag, host_groups
        key_label = "$C,BLUE_CYAN$#{key}$C,RST$"
        case host_groups_flag
        when :none
          @op.setting.set key, value
          reply "setting `#{key_label}` has been set to `$C,BLUE_CYAN$#{@op.setting.get key}$C,RST$`"
        when :all
          @op.setting.set key, value
          host_groups.each do |host_group|
            @op.setting.set key, value, host_group_id: host_group.id
          end
          reply "setting `#{key_label}` has been set to `$C,BLUE_CYAN$#{@op.setting.get key}$C,RST$` for all host groups"
        when :some
          host_groups.each do |host_group|
            @op.setting.set key, value, host_group_id: host_group.id
          end
          reply "setting `#{key_label}` has been set to `$C,BLUE_CYAN$#{value}$C,RST$` for host groups: $C,ORANGE$#{host_groups.collect(&:name).join(", ")}$C,ORANGE$"
        end
      end

      private
      def parse_set_command
        key = @args.shift
        value = @args.shift
        host_groups_arg = @args.shift

        case host_groups_arg
        when 'hostgroups-all'
          host_groups = Zabbix::HostGroup.get
          host_groups_flag = :all
        when 'hostgroups'
          names = @args.join(" ").split(",").collect(&:strip)
          raise UserInputError, ['no hostgroups specified'] + Array.wrap(help_features["settings set"]) if names.empty?
          host_groups = find_host_groups names
          host_groups_flag = :some
        when nil, ""
          host_groups = []
          host_groups_flag = :none
        else
          raise UserInputError, help_features["settings set"]
        end
        [key, value, host_groups_flag, host_groups]
      end
    end
  end
end