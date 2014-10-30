module Zabbirc
  class ServiceMock < Service
    include Cinch::Test
    def initialize plugin, opts={}, &b
      @_test_plugin = plugin
      @_test_opts = opts
      @_test_b = b
      super()
      setup_ops
    end

    def initialize_bot
      @cinch_bot = make_bot(@_test_plugin, @_test_opts, &@_test_b)

      # Stores reference to this Zabbirc::Service to be available in plugins
      @cinch_bot.instance_variable_set :@zabbirc_service, self
      @cinch_bot.class_eval do
        attr_reader :zabbirc_service
      end
    end

    def setup_ops
      setup_op "op1"
      setup_op "op2"
    end

    def setup_op name
      @@op_ids ||= 0
      irc_user = Cinch::User.new name, @cinch_bot
      zabbix_user = Zabbix::User.new(alias: name, userid: (@@op_ids+=1))
      @ops[name] = Op.new zabbix_user: zabbix_user, irc_user: irc_user
    end
  end
end