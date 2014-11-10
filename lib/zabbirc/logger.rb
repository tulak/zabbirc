module Zabbirc
  def self.logger
    synchronize do
      @logger ||= ::Logger.new(STDERR, 10, 1.megabyte).tap do |logger|
        logger.formatter = Zabbirc::Logger::Formatter.new
      end
    end
  end

  module Logger
    class Formatter
      Format = "%s, [%s#%d T%d] %5s -- %s: %s\n"

      attr_accessor :datetime_format

      def initialize
        @datetime_format = nil
      end

      def call(severity, time, progname, msg)
        Format % [severity[0..0], format_datetime(time), $$, Thread.current.object_id, severity, progname, msg2str(msg)]
      end

      private

      def format_datetime(time)
        if @datetime_format.nil?
          time.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d " % time.usec
        else
          time.strftime(@datetime_format)
        end
      end

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
              (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end
    end
  end
end