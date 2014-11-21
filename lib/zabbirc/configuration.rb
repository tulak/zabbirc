require 'active_support/configurable'

module Zabbirc
  def self.configure(&block)
    block.call(@config ||= Zabbirc::Configuration.new)
  end

  def self.config
    @config
  end

  class Configuration #:nodoc:
    include ActiveSupport::Configurable

    config_accessor :zabbix_api_url
    config_accessor :zabbix_login
    config_accessor :zabbix_password

    config_accessor :irc_server
    config_accessor :irc_channels

    config_accessor :events_check_interval
    config_accessor :notify_about_events_from_last

    def param_name
      config.param_name.respond_to?(:call) ? config.param_name.call : config.param_name
    end

    # define param_name writer (copied from AS::Configurable)
    writer, line = 'def param_name=(value); config.param_name = value; end', __LINE__
    singleton_class.class_eval writer, __FILE__, line
    class_eval writer, __FILE__, line
  end

  # this is ugly. why can't we pass the default value to config_accessor...?
  configure do |config|
    config.events_check_interval = 10.seconds
    config.notify_about_events_from_last = 5.minutes

    config.irc_server = "irc.freenode.org"
    config.irc_channels = ["#zabbirc-test", "#zabbirc-test-2"]
  end
end