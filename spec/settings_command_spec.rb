describe Zabbirc::Irc::SettingsCommand do
  let(:ops_builder) { Zabbirc::OpsBuilder.new }
  let(:mock_nick) { "op1" }
  let(:mock_op) { ops_builder.build_op(mock_nick, mock_user_settings) }
  let(:mock_message) { double("Cinch::Message", user: mock_op.irc_user) }
  let(:mock_user_settings) { nil }
  let(:settings_command) { Zabbirc::Irc::SettingsCommand.new ops_builder.ops, mock_message, cmd }


  describe "#show_settings" do
    let(:mock_user_settings) { {primary_channel: "#channel-1", events_priority: "high", notify: false } }
    let(:expected_msg) { "#{mock_nick}: notify: false, notify_recoveries: true, primary_channel: #channel-1, events_priority: high, host_groups: {}" }
    let(:cmd) { "show" }
    it "should show settings" do
      expect(mock_message).to receive(:reply).with(expected_msg)
      settings_command.run
    end
  end

  describe "#set_setting" do
    shared_examples "set_setting" do |key, value, expected_setting_value|
      let(:expected_msg) { "#{mock_nick}: setting `#{key}` has been set to `#{expected_setting_value}`" }
      let(:cmd) { "set #{key} #{value}"}
      it "should set #{key} setting to #{value}" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        settings_command.run
        expect(mock_op.setting.get(key)).to eq expected_setting_value
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
        mock_op.add_channel double("#channel1", name: "#channel1")
        mock_op.add_channel double("#channel2double", name: "#channel2")
      end
      it_should_behave_like "set_setting", "primary_channel", "#channel1", "#channel1"
      it_should_behave_like "set_setting", "primary_channel", "#channel2", "#channel2"
    end

  end
end