module Zabbirc
  STORED_SETTINGS_FILE = Zabbirc::RUNTIME_DATA_DIR.join("ops_settings.yaml")
  class OpList
    include Enumerable

    def initialize ops=nil
      @ops = {}
      if ops
        ops.each do |op|
          add op
        end
      end
    end

    def authenticate name
      @ops.key? name
    end

    alias_method :exists?, :authenticate

    def get name
      @ops[name]
    end

    def add op
      if exists? op.login
        return get(op.login)
      end
      @ops[op.login] = op
    end

    def each &block
      @ops.values.each &block
    end

    def interested_in event
      self.class.new(find_all{ |op| op.interested_in? event })
    end

    def notify event
      group_by(&:primary_channel).each do |channel, ops|
        next if channel.nil?
        op_targets = ops.collect{|op| "#{op.nick}:" }.join(" ")
        channel.send "#{op_targets} #{event.label}"
        ops.each{ |op| op.event_notified event }
      end
    end

    def dump_settings
      dump = {}
      each do |op|
        dump[op.login] = op.setting
      end

      file = File.open(STORED_SETTINGS_FILE, "w")
      file.puts dump.to_yaml
      file.close
      true
    end

    def load_settings
      return unless File.exists?(STORED_SETTINGS_FILE)
      stored_settings = YAML.load_file(STORED_SETTINGS_FILE)
      stored_settings.each do |login, setting|
        op = get(login)
        next unless op
        op.set_setting setting
      end
    end
  end
end