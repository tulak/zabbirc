require 'active_support/all'
require 'pry'
require 'singleton'

# $:.unshift(File.expand_path(File.dirname(__FILE__)))

require "zabbix_irc_bot/configuration"
require "zabbix_irc_bot/cli"

require "zabbix_irc_bot/zabbix/connection"
require 'zabbix_irc_bot/zabbix/resource'
require 'zabbix_irc_bot/zabbix/event'
require 'zabbix_irc_bot/zabbix/trigger'

module ZabbixIrcBot
end

require_relative "../config/config"

include ZabbixIrcBot::Zabbix
binding.pry