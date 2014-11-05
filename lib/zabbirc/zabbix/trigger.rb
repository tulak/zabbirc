module Zabbirc
  module Zabbix
    class Trigger < Resource::Base
      has_many :hosts

      def priority
        Priority.new(super.to_i)
      end
    end
  end
end
