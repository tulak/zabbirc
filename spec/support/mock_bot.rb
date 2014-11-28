module Zabbirc
  class MockBot
    include Zabbirc::Irc::PluginMethods
    include RSpec::Mocks::ExampleMethods

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

    def get_login obj
      return obj if obj.is_a? String
      return obj.login if obj.respond_to? :login
      return get_login(obj.user) if obj.respond_to? :user
    end

    def setup_op name, settings=nil
      @@op_ids ||= 0
      zabbix_user = Zabbix::User.new(alias: name, userid: (@@op_ids+=1))
      irc_user = double "IrcUser", nick: name, user: name
      op = Op.new(zabbix_user)
      op.set_irc_user irc_user
      settings.each do |key, value|
        op.setting.set key, value
      end if settings
      @ops.add op
    end
  end
end