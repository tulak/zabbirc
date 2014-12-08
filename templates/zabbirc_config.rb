Zabbirc.configure do |config|
  ### Zabbix server configuration
  config.zabbix_api_url = "https://your.zabbix-server.com/zabbix/api_jsonrpc.php"
  config.zabbix_login = "zabbirc"
  config.zabbix_password = "zabbircpass"

  ### IRC configurations
  # config.irc_server = "irc.freenode.org"
  # config.irc_channels = ["#zabbirc-test", "#zabbirc-test-2"]

  ### Zabbirc configurations
  # config.events_check_interval = 10.seconds
  # config.notify_about_events_from_last = 5.minutes
  # config.default_events_priority = :high
end