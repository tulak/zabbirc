module Zabbirc
  module Services
    class Ops < Base
      def iterate
        @mutex.synchronize do
          @cinch_bot.channels.each do |channel|
            sync_ops channel
          end
        end
      end

      private

      def channel_nicks channel
        channel.users.keys.collect(&:nick)
      end

      def channel_find_user channel, nick
        channel.users.keys.find { |irc_user| irc_user.nick == nick }
      end

      def sync_ops channel
        nicks        = channel_nicks channel
        zabbix_users = Zabbix::User.get filter: { alias: nicks }
        zabbix_users.each do |zabbix_user|
          irc_user = channel_find_user channel, zabbix_user.alias
          op       = (@service.ops[zabbix_user.alias] ||= Op.new(zabbix_user: zabbix_user, irc_user: irc_user))
          op.add_channel channel
        end

        @service.ops.each do |nick, op|
          op.remove_channel channel unless nicks.include? nick
        end

        @service.ops.each do |nick, op|
          @service.ops.delete(op) if op.channels.empty?
        end
        true
      end
    end
  end
end