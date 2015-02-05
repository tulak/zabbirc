module Zabbirc
  class OpsBuilder
    include RSpec::Mocks::ExampleMethods

    attr_reader :ops
    def initialize
      @ops = OpList.new
    end

    def build_op name, settings=nil
      @op_ids ||= 0
      zabbix_user = Zabbix::User.new(alias: name, userid: (@op_ids+=1))
      irc_user = double "Cinch::User", nick: name, user: name
      op = Op.new(zabbix_user)
      op.set_irc_user irc_user
      settings.each do |key, value|
        op.setting.set key, value
      end if settings
      @ops.add op
      op
    end
  end
end