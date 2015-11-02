require_relative "plugin_methods"

module Zabbirc
  module Irc
    class Plugin
      include Cinch::Plugin
      include PluginMethods

      listen_to :join, method: :sync_ops
      listen_to :leaving, method: :sync_ops

      match /zabbirc status\s*$/, method: :zabbirc_status

      # Help
      match /zabbirc help(?: (.*))?\Z/, method: :help_command

      # Settings
      match /settings(?: (.*))?\Z/, method: :settings_command

      # Events
      match /((?:ack|events)(?: .*)?)/, method: :event_command

      # Host
      match /((?:status|latest)(?: .*)?)/, method: :host_command
    end
  end
end