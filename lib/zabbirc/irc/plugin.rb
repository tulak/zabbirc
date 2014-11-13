require_relative "plugin_methods"

module Zabbirc
  module Irc
    class Plugin
      include Cinch::Plugin
      include PluginMethods

      listen_to :join, method: :sync_ops
      listen_to :leaving, method: :sync_ops

      match "settings", method: :show_settings
      match /settings set ([#_a-zA-Z0-9]+)( ([#\-_a-zA-Z0-9]+))?/, method: :set_setting
      match "events", method: :list_events
      match /status ([a-zA-Z0-9\-.]+)/, method: :host_status
    end
  end
end