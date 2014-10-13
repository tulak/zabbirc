require 'zabbix/client'

module ZabbixIrcBot
  module Zabbix
    class Connection
      include Singleton
      attr_reader :client
      def initialize
        @client = ::Zabbix::Client.new(ZabbixIrcBot.config.zabbix_api_url, debug: false)
        @client.user.login(user: ZabbixIrcBot.config.zabbix_login, password: ZabbixIrcBot.config.zabbix_password)
      end
    end
  end
end