module Zabbirc
  class Setting
    DEFAULTS = ActiveSupport::HashWithIndifferentAccess.new({
        notify: true,
        notify_recoveries: true,
        primary_channel: nil,
        events_priority: Zabbirc.config.default_events_priority
    })

    def initialize
      @options = ActiveSupport::HashWithIndifferentAccess.new DEFAULTS.deep_dup
    end

    def restore stored_options
      stored_options = ActiveSupport::HashWithIndifferentAccess.new stored_options
      unknown_keys = stored_options.keys - DEFAULTS.keys
      stored_options.delete_if{|k,_v| unknown_keys.include? k }
      @options = DEFAULTS.deep_dup.merge(stored_options)
    end

    def set name, value
      @options[name] = value
    end

    def get name
      @options[name]
    end

    def fetch name, value
      @options[name] ||= value
    end

    def to_s
      @options.collect do |k, v|
        "#{k}: #{v}"
      end.join(", ")
    end

    def to_hash
      @options.to_hash.deep_dup
    end
  end
end