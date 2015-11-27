require 'active_support/configurable'
require 'active_support/all'

require 'zabbirc/priority'

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

    config_accessor :colors

    def param_name
      config.param_name.respond_to?(:call) ? config.param_name.call : config.param_name
    end

    def default_events_priority= value
      allowed_priorities = Priority::PRIORITIES.values
      unless allowed_priorities.include? value
        raise ArgumentError, "Unexpected value in config file. default_events_priority can be one of `#{allowed_priorities.collect(&:inspect).join(", ")}` but `#{value.inspect}` was stated"
      end
      config.default_events_priority = value
    end

    def default_events_priority
      config.default_events_priority
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
    config.default_events_priority = :high

    config.irc_server = "irc.freenode.org"
    config.irc_channels = ["#zabbirc-test", "#zabbirc-test-2"]
    config.colors = true
  end
end