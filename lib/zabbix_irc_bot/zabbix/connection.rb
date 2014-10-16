require 'zabbix/client'

module ZabbixIrcBot
  module Zabbix
    class Connection
      attr_reader :client

      def self.get_connection
        Thread.current[:zabbix_connection] ||= self.new
      end

      def initialize
        @client = ::Zabbix::Client.new(ZabbixIrcBot.config.zabbix_api_url, debug: false)
        @client.user.login(user: ZabbixIrcBot.config.zabbix_login, password: ZabbixIrcBot.config.zabbix_password)
      end
    end
  end
end