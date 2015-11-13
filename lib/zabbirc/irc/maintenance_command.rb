module Zabbirc
  module Irc
    class MaintenanceCommand < BaseCommand
      register_help "maint", [
          "Show active maintenances: !maint",
          "Schedule a maintenance: !maint [hostgroups] '<host_name>|<hostgroup_name>[, <host_name>|<hostgroup_name>]' <duration> <reason>",
          " - duration format: 1h, 30m, 1h30m. h - hour, m - minute.",
          "Delete a maintenance: !maint delete <maintenance-id>"
      ]
      private
      def perform
        first_arg = @args.first
        case first_arg
        when nil
          perform_list
        when "delete"
          @args.shift
          perform_delete
        else
          perform_create
        end
      end

      def perform_list
        maintenances = Zabbix::Maintenance.get(selectHosts: :extend, selectGroups: :extend, selectTimePeriods: :extend)
        active_maintenances = maintenances.select(&:active?)
        if active_maintenances.empty?
          reply "No active maintenances at this moment."
        else
          reply active_maintenances.collect(&:label)
        end

      end

      def perform_create
        params = {}
        hostgroups_flag = @args.shift
        if hostgroups_flag == "hostgroups"
          target_names = @args.shift
          raise UserInputError, help_features["maint"] unless target_names
          target_names = target_names.split(/,/).collect(&:strip)
          params[:host_group_ids] = find_host_groups(target_names).collect(&:id)
        else
          target_names = hostgroups_flag.split(/,/).collect(&:strip)
          params[:host_ids] = find_hosts(target_names).collect(&:id)
        end

        params[:duration] = parse_duration @args.shift
        params[:name] = @args.join(" ")
        raise raise UserInputError, "no reason specified" if params[:name].blank?

        id = Zabbix::Maintenance.create params
        maintenance = Zabbix::Maintenance.find(id)
        reply [
                "maintenance scheduled since #{maintenance.active_since.to_formatted_s(:short)} till #{maintenance.active_till.to_formatted_s(:short)}",
                maintenance.label
              ]
      end

      def perform_delete
        maintenance = find_maintenance @args.shift

        begin
          maintenance.destroy
          reply "maintenance with id #{maintenance.shorten_id} has been deleted"
        rescue ::Zabbix::Client::Error => e
          reply "an error occured while deleting maintenance with id #{maintenance.shorten_id}: #{e}"
        end
      end

      def find_maintenance shorten_id
        maintenance_id = Zabbirc.maintenances_id_shortener.get_id shorten_id
        raise UserInputError, "Bad maintenance id `#{shorten_id}`" unless maintenance_id

        maintenance = Zabbix::Maintenance.find(maintenance_id)
        raise UserInputError, "Could not find maintenance with id `#{shorten_id}`" if maintenance.nil?
        maintenance

      rescue Zabbix::IDNotUniqueError => e
        raise UserInputError, "Could not find maintenance: #{e}"
      end

      def find_targets names, hostgroups_flag
        names = names.split(/,/).collect(&:strip)
        if hostgroups_flag
          find_host_groups names
        else
          find_hosts names
        end
      end

      def parse_duration duration_str
        raise UserInputError, help_features["maint"] unless duration_str
        match_data = duration_str.match(/(?:(?<minutes>[0-9]+[mM])|(?:(?<hours>[0-9]+)[hH](?<minutes>[0-9]+[mM])?))/)
        raise UserInputError, ["cannot parse duration `#{duration_str}`", help_features["maint"]].flatten unless match_data
        duration = 0
        duration += match_data[:hours].to_i.hours if match_data[:hours]
        duration += match_data[:minutes].to_i.minutes if match_data[:minutes]
        duration
      end
    end
  end
end
