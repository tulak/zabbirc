describe Zabbirc::Irc::PluginMethods do
  # let(:service) { Zabbirc::ServiceMock.new }
  let(:mock_message) { double("mock_message", user: mock_user) }
  let(:mock_user) { double("mock_user", nick: mock_nick) }
  let(:bot) { Zabbirc::MockBot.new }
  let(:mock_nick) { "op1" }

  before do
    allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return(recent_events)
    bot.setup_op mock_nick
  end

  describe "#list_events" do
    context "no last events" do
      let(:recent_events) { [] }

      it "should report no last events" do
        expect(mock_message).to receive(:reply).with("#{mock_nick}: No last events")
        bot.list_events mock_message
      end
    end

    context "no last events" do
      let(:event1) { double "Event1", label: "Event 1 label" }
      let(:event2) { double "Event2", label: "Event 2 label" }
      let(:recent_events) { [event1, event2] }

      it "should report no last events" do
        expected_msg = recent_events.collect{|e| "#{mock_nick}: #{e.label}"}.join("\n")
        expect(mock_message).to receive(:reply).with(expected_msg)
        bot.list_events mock_message
      end
    end
  end
end