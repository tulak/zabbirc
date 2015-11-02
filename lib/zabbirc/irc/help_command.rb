module Zabbirc
  module Irc
    class HelpCommand < BaseCommand

      private
      def perform
        command = @args.join(" ")
        case command
        when nil, ""
          reply "Zabbirc - Zabbix IRC Bot - available commands: #{help_features.keys.join(", ")}. Type '!zabbirc help <command>' for detailed help"
        when *help_features.keys
          reply help_features[command], prefix: "HELP #{command}: "
        else
          reply "Unknown help command: #{command}"
        end
      end

    end
  end
end
