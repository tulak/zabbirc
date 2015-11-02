module Zabbirc
  module Irc
    HELP_FEATURES = {}
    class BaseCommand
      def self.register_help command, description
        raise ArgumentError, "command `#{command}` already registered" if HELP_FEATURES.key? command
        HELP_FEATURES[command] = description
      end

      def help_features
        HELP_FEATURES
      end

      attr_reader :op
      def initialize ops, message, cmd
        @ops = ops
        @message = message
        @op = get_op @message
        @cmd = cmd.to_s.strip.gsub(/\s{2,}/," ")
        @args = @cmd.split(/ /)
      end

      def run
        return unless authenticated?
        begin
          perform # perform method should be implemented in subclass
        rescue Zabbix::NotConnected => e
          reply "#{e.to_s}"
        end
      end

      private

      def authenticated?
        @op.present?
      end

      def get_op obj
        login = get_login obj
        @ops.get login
      end

      def get_login obj
        case obj
        when Cinch::Message
          obj.user.user.sub("~","")
        when Cinch::User
          obj.user.user.sub("~","")
        when String
          obj
        else
          # Used for tests
          return obj.login if obj.respond_to? :login
          return get_login(obj.user) if obj.respond_to? :user
        end
      end

      def reply msg, *options
        options = options.extract_options!.reverse_merge(prefix: "")
        msg = Array.wrap msg
        msg = msg.collect do |m|
          "#{@op.nick}: #{options[:prefix]}#{m}"
        end.join("\n")

        @message.reply msg
      end

      def find_host host
        hosts = Zabbix::Host.get(search: {host: host})
        case hosts.size
        when 0
          reply "Host not found `#{host}`"
        when 1
          return hosts.first
        when 2..10
          reply "Found #{hosts.size} hosts: #{hosts.collect(&:name).join(', ')}. Be more specific"
        else
          reply "Found #{hosts.size} Be more specific"
        end
        false
      end

      def find_event short_eventid
        begin
          eventid = Zabbirc.events_id_shortener.get_id short_eventid
          unless eventid
            reply "Bad event id `#{short_eventid}`"
            return false
          end
          event = Zabbix::Event.find(eventid, {selectHosts: :extend, selectRelatedObject: :extend})
          if event.nil?
            reply "Could not find event with id `#{short_eventid}`"
            return false
          end
          event
        rescue Zabbix::IDNotUniqueError => e
          reply "Could not find event: #{e}"
          false
        end
      end

      def parse_priority priority
        Priority.new(priority)
      rescue ArgumentError => e
        reply("#{e}")
        nil
      end
    end
  end
end
