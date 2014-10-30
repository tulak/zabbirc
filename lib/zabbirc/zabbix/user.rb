module Zabbirc
  module Zabbix
    class User < Resource::Base
      def self.find_by_alias _alias, options={}
        options = options.merge filter: { alias: _alias  }
        get(options).first
      end
    end
  end
end
