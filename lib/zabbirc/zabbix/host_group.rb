module Zabbirc
  module Zabbix
    class HostGroup < Resource::Base
      set_model_name "hostgroup"
      set_id_attr_name "groupid"
    end
  end
end
