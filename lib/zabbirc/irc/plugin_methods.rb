module Zabbirc
  module Irc
    module PluginMethods
      extend ActiveSupport::Concern
      include Help

      def zabbirc_status m
        ops_msg = ops.find_all{|o| o.nick.present? }.collect{|o| "#{o.nick} as #{o.login}"}
        msg = []
        version = "Zabbirc #{Zabbirc::VERSION}"
        if Zabbix::Connection.test_connection
          msg << "#{m.user.nick}: #{version} - Zabbix API connection successfull"
        else
          msg << "#{m.user.nick}: #{version} - Zabbix API connection FAILED !!!"
        end
        msg << "#{m.user.nick}: Identified ops: #{ops_msg.join(", ")}"
        m.reply msg.join("\n")
      rescue Zabbix::NotConnected => e
        rescue_not_connected m, e
      end

      def help_command m, cmd
        cmd = HelpCommand.new(ops, m, cmd)
        cmd.run
      end

      def host_command m, cmd
        cmd = HostCommand.new(ops, m, cmd)
        cmd.run
      end

      def settings_command m, cmd
        cmd = SettingsCommand.new(ops, m, cmd)
        cmd.run
      end

      def event_command m, cmd
        cmd = EventCommand.new(ops, m, cmd)
        cmd.run
      end

      def sync_ops m, u=nil
        return if u and u.nick == bot.nick
        bot.zabbirc_service.ops_service.iterate
      end

      def ops
        @ops ||= bot.zabbirc_service.ops
      end

      ### Authentication and helpers

      def get_op obj
        login = get_login obj
        ops.get login
      end

      alias_method :authenticate, :get_op

      def get_login obj
        case obj
        when Cinch::Message
          obj.user.user.sub("~","")
        when Cinch::User
          obj.user.user.sub("~","")
        when String
          obj
        end
      end

      private

      def rescue_not_connected m, e
        op = get_op m
        return unless op
        m.reply "#{op.nick}: #{e.to_s}"
      end
    end
  end
end