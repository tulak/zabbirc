require 'zabbix/client'

module Zabbirc
  module Zabbix
    class Connection
      attr_reader :client

      def self.get_connection
        Thread.current[:zabbix_connection] ||= self.new
      end

      def self.down!
        @@down = true
      end

      def self.down?
        @@down == true
      end

      def self.up!
        @@down = false
      end

      def self.up?
        @@down == false
      end

      def self.test_connection
        self.new
        self.up!
        true
      rescue => e
        Zabbirc.logger.fatal "Could not connect to zabbix: #{e}"
        self.down!
        false
      end

      def initialize
        @client = ::Zabbix::Client.new(Zabbirc.config.zabbix_api_url, debug: false)
        @client.user.login(user: Zabbirc.config.zabbix_login, password: Zabbirc.config.zabbix_password)
      end
    end

    class NotConnected < StandardError
      attr_reader :original_exception
      def initialize original_exception
        @original_exception = original_exception
      end

      def to_s
        "Cannot connect to Zabbix API: #{original_exception{}}"
      end
    end
  end
end