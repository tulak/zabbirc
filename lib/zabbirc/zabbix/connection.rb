require 'zabbix/client'

module Zabbirc
  module Zabbix
    class Connection
      attr_reader :client

      def self.get_connection
        Thread.current[:zabbix_connection] ||= self.new
      end

      def initialize
        @client = ::Zabbix::Client.new(Zabbirc.config.zabbix_api_url, debug: false)
        @client.user.login(user: Zabbirc.config.zabbix_login, password: Zabbirc.config.zabbix_password)
      end
    end
  end
end