module Zabbirc
  module Zabbix
    class Event < Resource::Base
      has_many :hosts

      def self.recent options={}
        params = {
            acknowledged: false,
            time_from: Zabbirc.config.notify_about_events_from_last.ago.utc.to_i,
            priority_from: 0,
            selectRelatedObject: :extend,
            selectHosts: :extend
        }.merge(options)



        priority_from = Priority.new(params.delete(:priority_from))
        events = get params

        preload_host_groups events

        events = events.find_all{|e| e.priority >= priority_from }
        events.sort{|x,y| x.priority <=> y.priority }
      end

      def self.preload_host_groups events
        host_ids = events.flat_map(&:hosts).collect(&:id).uniq
        hosts = Host.get(hostids: host_ids, selectGroups: :extend)
        events.each do |event|
          event_host_ids = event.hosts.collect(&:id)
          event.host_groups = hosts.select{|h| event_host_ids.include? h.id }.flat_map(&:groups)
        end
      end

      attr_reader :attrs
      attr_writer :host_groups

      delegate :priority, :priority_code, :severity_label, to: :related_object

      def related_object
        raise AttributeError, "`source` attribute required" if @attrs[:source].blank?
        raise AttributeError, "`object` attribute required" if @attrs[:object].blank?
        @related_object ||= determine_related_object
      end

      def host_groups
        @host_groups ||= begin
          host_ids = hosts.collect(&:id).uniq
          hosts = Host.get(hostids: host_ids, selectGroups: :extend)
          hosts.flat_map(&:groups)
        end
      end

      def acknowledge message
        res = api.event.acknowledge(eventids: id, message: message)
        res["eventids"].collect(&:to_i).include? id.to_i
      end

      def acknowledged?
        acknowledged.to_i == 1
      end

      def maintenance?
        maintenace_host_ids = Maintenance.cached(created_at).flat_map{|m| m.hosts.map(&:id) }
        event_host_ids = hosts.flat_map(&:id)
        return true if (maintenace_host_ids & event_host_ids).any?

        maintenace_group_ids = Maintenance.cached(created_at).flat_map{|m| m.groups.map(&:id) }
        event_group_ids = host_groups.flat_map(&:id)
        return true if (maintenace_group_ids & event_group_ids).any?
        false
      end

      def maintenance_label
        " $C,PURPLE [MAINT] $C" if maintenance?
      end

      def created_at
        Time.at(clock.to_i)
      end

      def value
        case @attrs[:source].to_i
        when 0
          case @attrs[:value].to_i
          when 0
            :ok
          when 1
            :problem
          end
        else
          @attrs[:value]
        end
      end

      def shorten_id
        @shorten_id ||= Zabbirc.events_id_shortener.get_shorten_id id
      end

      def state
        case value
        when :ok then "$C,GREEN ok $C,RST"
        when :problem then "$C,RED problem $C,RST"
        else
          value
        end
      end

      def message
        desc = related_object.description
        host_label_regexp = Regexp.union("{HOSTNAME}", "{HOST.NAME}")
        host_names = "$U#{hosts.collect(&:host).join(', ')}$U,RST"
        if desc =~ host_label_regexp
          desc.sub(host_label_regexp, host_names)
        else
          "#{desc} on #{host_names}"
        end
      end

      def label
        format_label "$C,PURPLE |%sid| $C,RST %time %severity%maint %msg - %state"
      end

      def format_label fmt
        fmt.gsub("%priority-code", "#{priority.code}").
            gsub("%priority-num", "#{priority.number}").
            gsub("%severity", "#{severity_label}").
            gsub("%time", "#{created_at.to_formatted_s(:short)}").
            gsub("%msg", "#{message}").
            gsub("%id", "#{id}").
            gsub("%sid", "#{shorten_id}").
            gsub("%state", "#{state}").
            gsub("%maint", "#{maintenance_label}")
      end

      def any_host_matches? regexp
        hosts.any?{|h| h.name =~ regexp }
      end

      private

      def determine_related_object
        case @attrs[:object].to_i
        when 0
          @attrs[:relatedObject] ? Trigger.new(@attrs[:relatedObject]) : Trigger.find(@attrs[:objectid])
        else
          raise StandardError, "related object #{@attrs[:object].to_i} not implemented yet"
        end
      end
    end
  end
end