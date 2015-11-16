module Zabbirc
  module Zabbix
    class Maintenance < Resource::Base

      CACHE_TTL = 1.minute
      has_many :hosts
      has_many :groups, class_name: "HostGroup"

      def self.find id, *options
        options = options.extract_options!
        options[:selectHosts] = :extend
        options[:selectGroups] = :extend
        super(id, options)
      end

      def self.create *options
        default_options = {
            host_ids: [],
            host_group_ids: [],
            without_data_collection: false
        }

        options = options.extract_options!
        options = options.reverse_merge(default_options)

        duration = options[:duration]
        name = options[:name]
        host_ids = options[:host_ids]
        host_group_ids = options[:host_group_ids]
        maint_start = Time.current
        maint_end = maint_start + duration

        r = api.maintenance.create(
            name: name,
            active_since: maint_start.to_i,
            active_till: maint_end.to_i,
            hostids: host_ids,
            groupids: host_group_ids,
            maintenance_type: (options[:without_data_collection] ? 1 : 0),
            timeperiods: [
                {
                    timeperiod_type: 0,
                    start_time: maint_start.to_i,
                    period: duration
                }
            ]
        )

        r["maintenanceids"].first
      end

      def self.cached timestamp = nil
        if @maintenances_timestamp and @maintenances_timestamp < CACHE_TTL.ago
          @maintenances, @maintenances_timestamp = nil, nil
        end
        @maintenances_timestamp ||= Time.current
        @maintenances ||= Maintenance.get(selectHosts: :extend, selectGroups: :extend)

        if timestamp
          @maintenances.select{|maintenance| maintenance.active_range.cover?(timestamp) }
        else
          @maintenances
        end
      end

      def shorten_id
        @shorten_id ||= Zabbirc.maintenances_id_shortener.get_shorten_id id
      end

      def active_since
        Time.at(super.to_i)
      end

      def active_till
        Time.at(super.to_i)
      end

      def active_range
        active_since..active_till
      end

      def active?
        (active_since..active_till).cover? Time.current
      end

      def data_collection_label
        " [NO-DATA-COL]" if maintenance_type.to_i == 1
      end

      def label
        format_label "|%sid|%data-collection-label %start -> %end >> %name %targets"
      end

      def format_label fmt
        fmt.gsub("%start", "#{active_since.to_formatted_s(:short)}").
            gsub("%end", "#{active_till.to_formatted_s(:short)}").
            gsub("%name", "#{name}").
            gsub("%id", "#{id}").
            gsub("%sid", "#{shorten_id}").
            gsub("%targets", "#{target_labels}").
            gsub("%data-collection-label", "#{data_collection_label}")
      end

      def target_labels
        host_names = hosts.collect(&:name)
        group_names = groups.collect(&:name)

        r = ""
        r << "Hosts: #{host_names.join(", ")}" if host_names.present?
        r << "Host Groups: #{group_names.join(", ")}" if group_names.present?
        r
      end

      def destroy
        api.maintenance.delete [id]
      end

    end
  end
end
