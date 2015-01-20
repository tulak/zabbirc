module Zabbirc
  module Zabbix
    class Host < Resource::Base
      has_many :groups, class_name: "HostGroup"
    end
  end
end
