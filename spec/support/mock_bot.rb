module Zabbirc
  class MockBot
    include Zabbirc::Irc::PluginMethods

    def initialize
      @ops = OpList.new
    end

    def get_op obj
      nick = get_nick obj
      @ops.get nick
    end

    def setup_op name
      @@op_ids ||= 0
      zabbix_user = Zabbix::User.new(alias: name, userid: (@@op_ids+=1))
      @ops.add Op.new(zabbix_user: zabbix_user, irc_user: Object.new)
    end
  end
end