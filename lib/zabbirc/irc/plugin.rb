require_relative "plugin_methods"

module Zabbirc
  module Irc
    class Plugin
      include Cinch::Plugin
      include PluginMethods

      listen_to :join, method: :sync_ops
      listen_to :leaving, method: :sync_ops

      match "zabbirc status", method: :zabbirc_status
      match "settings", method: :show_settings
      match /settings set ([#_a-zA-Z0-9]+)( ([#\-_a-zA-Z0-9]+))?/, method: :set_setting
      match /settings set\s*$/, method: :set_setting_help
      match "events", method: :list_events
      match /status ([a-zA-Z0-9\-.]+)/, method: :host_status
      match /latest ([a-zA-Z0-9\-.]+)( (\d+))?/, method: :host_latest
      match /ack (\d+) (.*)/, method: :acknowledge_event
      match /ack\s*$/, method: :acknowledge_event_usage
      match /ack ([^ ]+)\s*$/, method: :acknowledge_event_usage
    end
  end
end