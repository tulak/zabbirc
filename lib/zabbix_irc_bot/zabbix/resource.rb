module ZabbixIrcBot
  module Zabbix
    class Resource
      def self.api
        Connection.instance.client
      end

      def api
        Connection.instance.client
      end

      def method_missing method, *args, &block
        if args.length == 0 and not block_given? and @attrs.key? method
          @attrs[method]
        else
          super
        end
      end
    end
  end
end