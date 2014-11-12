describe Zabbirc::Irc::PluginMethods do
  # let(:service) { Zabbirc::ServiceMock.new }
  let(:mock_message) { double("Cinch::Message", user: mock_user) }
  let(:mock_user) { double("Cinch::User", nick: mock_nick) }
  let(:bot) { Zabbirc::MockBot.new }
  let(:mock_nick) { "op1" }
  let(:mock_user_settings) { nil }

  before do
    bot.setup_op mock_nick, mock_user_settings
  end

  describe "#list_events" do
    before do
      allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return(recent_events)
    end
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
      let(:expected_msg) { recent_events.collect{|e| "#{mock_nick}: #{e.label}"}.join("\n") }

      it "should report no last events" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        bot.list_events mock_message
      end
    end
  end

  describe "#show_settings" do
    let(:mock_user_settings) { {primary_channel: "#channel-1", events_priority: "high", notify: false } }
    let(:expected_msg) { "#{mock_nick}: notify: false, primary_channel: #channel-1, events_priority: high" }
    it "should show settings" do
      expect(mock_message).to receive(:reply).with(expected_msg)
      bot.show_settings mock_message
    end
  end

  describe "#set_setting" do
    shared_examples "set_setting" do |key, value, expected_setting_value|
      let(:expected_msg) { "#{mock_nick}: setting `#{key}` was set to `#{expected_setting_value}`" }
      let(:op) { bot.get_op mock_nick }
      it "should set #{key} setting to #{value}" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        bot.set_setting mock_message, key, nil, value
        expect(op.setting.get(key)).to eq expected_setting_value
      end
    end


    context "notify" do
      it_should_behave_like "set_setting", "notify", "false", false
      it_should_behave_like "set_setting", "notify", "true", true
    end

    context "events_priority" do
      it_should_behave_like "set_setting", "events_priority", "high", :high
      it_should_behave_like "set_setting", "events_priority", "5", :disaster
    end

    context "primary_channel" do
      before do
        op.add_channel double("#channel1", name: "#channel1")
        op.add_channel double("#channel2double", name: "#channel2")
      end
      it_should_behave_like "set_setting", "primary_channel", "#channel1", "#channel1"
      it_should_behave_like "set_setting", "primary_channel", "#channel2", "#channel2"
    end

  end
end