module Zabbirc
  class MockBot
    include Zabbirc::Irc::PluginMethods

    def initialize
      @ops = OpList.new
    end

    def ops
      @ops
    end

    def get_nick obj
      return obj if obj.is_a? String
      return obj.nick if obj.respond_to? :nick
      return get_nick(obj.user) if obj.respond_to? :user
    end

    def setup_op name, settings=nil
      @@op_ids ||= 0
      zabbix_user = Zabbix::User.new(alias: name, userid: (@@op_ids+=1))
      op = Op.new(zabbix_user: zabbix_user, irc_user: Object.new)
      settings.each do |key, value|
        op.setting.set key, value
      end if settings
      @ops.add op
    end
  end
end