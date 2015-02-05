require_relative "plugin_methods"

module Zabbirc
  module Irc
    class Plugin
      include Cinch::Plugin
      include PluginMethods

      listen_to :join, method: :sync_ops
      listen_to :leaving, method: :sync_ops

      match /zabbirc help(?: (.*))?\Z/, method: :help_command
      match /zabbirc status\s*$/, method: :zabbirc_status

      # Settings
      match /settings(?: (.*))?\Z/, method: :settings_command

      # Events
      register_help "events", "Show events from last #{Zabbirc.config.notify_about_events_from_last.to_i / 60} minutes filtered by <priority> and <host>. Usage: !events [<priority [<host>]]"
      match /events(?: ([a-zA-Z0-9\-]+)(?: ([a-zA-Z0-9\-]+))?)?\s*$/, method: :list_events

      # Host
      match /((?:status|latest)(?: .*)?)/, method: :host_command

      # ACK
      register_help "ack", "Acknowledges event with message. Usage: !ack <event-id> <ack-message>"
      match /ack ([a-zA-Z0-9]+) (.*)/, method: :acknowledge_event
      match /(ack)\s*$/, method: :zabbirc_help_detail
      match /(ack) (?:[^ ]+)\s*$/, method: :zabbirc_help_detail
    end
  end
end