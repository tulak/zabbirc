module Zabbirc
  module Services
    class Ops < Base
      def iterate
        sync_ops
        synchronize do
          @service.ops.dump_settings
        end
      end

      def sync_ops
        synchronize do
          sync_zabbix
          @cinch_bot.channels.each do |channel|
            sync_irc channel
          end
        end
      rescue Zabbix::NotConnected => e
        if Zabbix::Connection.up?
          @service.ops.interested.notify e.to_s
          Zabbix::Connection.down!
        end
      end

      private

      def channel_logins channel
        channel.users.keys.collect{|u| u.user.sub("~","") }
      end

      def channel_find_user channel, login
        channel.users.keys.find { |irc_user| irc_user.user.sub("~","") == login }
      end

      def sync_irc channel
        logins = channel_logins channel

        logins.each do |login|
          irc_user = channel_find_user channel, login
          op = @service.ops.get login
          next unless op
          op.set_irc_user irc_user
          op.add_channel channel
        end

        @service.ops.each do |op|
          op.remove_channel channel unless logins.include? op.login
        end
        true
      end

      def sync_zabbix

        zabbix_users = Zabbix::User.get
        zabbix_users.each do |zabbix_user|
          op = Op.new(zabbix_user)
          @service.ops.add op
        end

        zabbix_logins = zabbix_users.collect(&:alias)
        @service.ops.each do |op|
          @service.ops.remove op unless zabbix_logins.include? op.login
        end
      end
    end
  end
end