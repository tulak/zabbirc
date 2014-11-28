module Zabbirc
  class Op

    attr_reader :channels, :setting, :nick, :login
    def initialize zabbix_user
      raise ArgumentError, 'zabbix_user' if zabbix_user.nil?
      @login= zabbix_user.alias
      @zabbix_user = zabbix_user

      @notified_events = {}
      @channels = Set.new
      @setting = Setting.new
    end

    def set_irc_user irc_user
      @irc_user = irc_user
      @nick = irc_user.nick
    end

    def unset_irc_user
      @irc_user = nil
      @nick = nil
    end

    def primary_channel
      channel = @channels.find{|c| c.name == @setting.get(:primary_channel) }
      channel || @setting.fetch(:primary_channel, @channels.first)
    end

    def set_setting setting
      @setting = setting
    end

    def interesting_priority
      Priority.new @setting.get(:events_priority)
    end

    def add_channel channel
      @setting.fetch :primary_channel, channel.name
      @channels << channel
    end

    def remove_channel channel
      @channels.delete channel

      if channel == @setting.get(:primary_channel)
        @setting.set :primary_channel, @channels.first.try(:name)
      end

      unset_irc_user if @channels.empty?
      true
    end

    def interested_in? event
      return false unless setting.get :notify
      return false if @notified_events.key? event.id
      event.priority >= interesting_priority
    end

    def event_notified event
      @notified_events[event.id] = Time.now
    end

    private

    def clear_notified_events
      @notified_events.delete_if do |event_id, timestamp|
        timestamp < (Zabbirc.config.notify_about_events_from_last * 2).seconds.ago
      end
    end
  end
end