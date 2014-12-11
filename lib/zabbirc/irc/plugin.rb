require_relative "plugin_methods"

module Zabbirc
  module Irc
    class Plugin
      include Cinch::Plugin
      include PluginMethods

      listen_to :join, method: :sync_ops
      listen_to :leaving, method: :sync_ops

      match /zabbirc help\s*$/, method: :zabbirc_help
      match /zabbirc help (.+)\s*$/, method: :zabbirc_help_detail
      match /zabbirc status\s*$/, method: :zabbirc_status

      # Settings
      register_help "settings", "Show your op specific settings. Usage: !settings"
      match "settings", method: :show_settings
      register_help "settings set", "Set your op specific settings. Usage: !setting set <setting-name> <setting-value>"
      match /settings set ([#_a-zA-Z0-9]+)(?: ([#\-_a-zA-Z0-9]+))?/, method: :set_setting
      match /(settings set)\s*$/, method: :zabbirc_help_detail

      # Events
      register_help "events", "Show events from last #{Zabbirc.config.notify_about_events_from_last.to_i / 60} minutes filtered by <priority> and <host>. Usage: !events [<priority [<host>]]"
      match /events(?: ([a-zA-Z0-9\-]+)(?: ([a-zA-Z0-9\-]+))?)?\s*$/, method: :list_events

      # Host
      register_help "status", "Show status of host. Usage: !status <hostname>"
      match /status ([a-zA-Z0-9\-.]+)/, method: :host_status
      register_help "latest", "Show last <N> (default 8) events of host. Usage: !latest <hostname> [<N>]"
      match /latest ([a-zA-Z0-9\-.]+)(?: (\d+))?/, method: :host_latest
      match /(latest)\s*$/, method: :zabbirc_help_detail

      # ACK
      register_help "ack", "Acknowledges event with message. Usage: !ack <event-id> <ack-message>"
      match /ack (\d+) (.*)/, method: :acknowledge_event
      match /(ack)\s*$/, method: :zabbirc_help_detail
      match /(ack) (?:[^ ]+)\s*$/, method: :zabbirc_help_detail
    end
  end
end