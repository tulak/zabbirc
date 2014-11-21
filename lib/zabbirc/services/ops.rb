module Zabbirc
  module Services
    class Ops < Base
      def iterate
        synchronize do
          @cinch_bot.channels.each do |channel|
            sync_ops channel
          end
        end
      end

      private

      def channel_logins channel
        channel.users.keys.collect{|u| u.user.sub("~","") }
      end

      def channel_find_user channel, login
        channel.users.keys.find { |irc_user| irc_user.user.sub("~","") == login }
      end

      def sync_ops channel
        logins = channel_logins channel
        zabbix_users = Zabbix::User.get filter: { alias: logins }
        zabbix_users.each do |zabbix_user|
          irc_user = channel_find_user channel, zabbix_user.alias
          op = @service.ops.add(Op.new(zabbix_user: zabbix_user, irc_user: irc_user))
          op.add_channel channel
        end

        @service.ops.each do |op|
          op.remove_channel channel unless logins.include? op.login
        end
        true
      end
    end
  end
end