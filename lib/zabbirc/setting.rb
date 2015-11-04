module Zabbirc
  class Setting
    DEFAULTS = ActiveSupport::HashWithIndifferentAccess.new({
        notify: true,
        notify_recoveries: true,
        primary_channel: nil,
        events_priority: Zabbirc.config.default_events_priority,
        host_groups: ActiveSupport::HashWithIndifferentAccess.new
    })

    delegate :collect, to: :@options
    def initialize
      @options = ActiveSupport::HashWithIndifferentAccess.new DEFAULTS.deep_dup
    end

    def restore stored_options
      stored_options = ActiveSupport::HashWithIndifferentAccess.new stored_options
      unknown_keys = stored_options.keys - DEFAULTS.keys
      stored_options.delete_if{|k,_v| unknown_keys.include? k }
      @options = DEFAULTS.deep_dup.merge(stored_options)
    end

    def set name, value, *options
      host_group_id = parse_host_group_id(options)
      if host_group_id
        set_with_host_group name, value, host_group_id
      else
        @options[name] = value
      end
    end

    def get name, *options
      host_group_id = parse_host_group_id(options)
      if host_group_id
        first_not_nil(host_group_options(host_group_id)[name], @options[name])
      else
        @options[name]
      end
    end

    def fetch name, value, *options
      host_group_id = parse_host_group_id(options)

      if host_group_id
        if host_group_options(host_group_id)[name].nil?
          set_with_host_group name, value, host_group_id
        else
          get name, host_group_id: host_group_id
        end
      else
        @options[name] ||= value
      end
    end

    def to_hash
      @options.to_hash.deep_dup
    end

    private
    def parse_host_group_id args
      args.extract_options![:host_group_id]
    end

    def set_with_host_group name, value, host_group_id
      if get(name) == value
        host_group_options(host_group_id).delete(name)
      else
        host_group_options(host_group_id)[name] = value
      end
    end

    def host_group_options host_group_id
      @options[:host_groups][host_group_id] ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def first_not_nil *args
      args.find{|x| not x.nil? }
    end
  end
end