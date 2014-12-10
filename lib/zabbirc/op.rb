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
      @mutex = Mutex.new
    end

    def synchronize &block
      @mutex.synchronize &block
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
      synchronize do
        return nil if @channels.empty?
        channel = @channels.find{|c| c.name == @setting.get(:primary_channel) }
        return channel if channel
        channel = @channels.first
        @setting.set(:primary_channel, channel.name)
        channel
      end
    end

    def interesting_priority
      Priority.new @setting.get(:events_priority)
    end

    def add_channel channel
      synchronize do
        @setting.fetch :primary_channel, channel.name
        @channels << channel
      end
    end

    def remove_channel channel
      synchronize do
        @channels.delete channel

        if channel == @setting.get(:primary_channel)
          @setting.set :primary_channel, @channels.first.try(:name)
        end

        unset_irc_user if @channels.empty?
        true
      end
    end

    def interested_in? event
      return false unless setting.get :notify
      return false if @notified_events.key? event.id
      event.priority >= interesting_priority
    end

    def event_notified event
      @notified_events[event.id] = Time.now
      clear_notified_events
    end

    private

    def clear_notified_events
      @notified_events.delete_if do |event_id, timestamp|
        timestamp < (Zabbirc.config.notify_about_events_from_last * 2).seconds.ago
      end
    end
  end
end