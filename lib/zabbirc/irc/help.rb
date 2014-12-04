module Zabbirc
  module Irc
    module Help
      extend ActiveSupport::Concern
      FEATURES = {}

      def help_features
        FEATURES
      end

      def zabbirc_help m
        op = authenticate m
        return unless op
        help = "#{op.nick}: Zabbirc - Zabbix IRC Bot - available commands: #{help_features.keys.join(", ")}. Type '!zabbirc help <command>' for detailed help"
        m.reply help
      end

      def zabbirc_help_detail m, command
        op = authenticate m
        return unless op
        if cmd_help = help_features[command]
          help = "HELP #{command}: #{cmd_help}"
        else
          help = "Uknown command: #{command}"
        end
        m.reply("#{op.nick}: #{help}")
      end

      module ClassMethods
        def register_help command, description
          FEATURES[command] = description
        end

        def help_features
          FEATURES
        end
      end
    end
  end
end
