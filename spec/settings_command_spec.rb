describe Zabbirc::Irc::SettingsCommand do
  let(:ops_builder) { Zabbirc::OpsBuilder.new }
  let(:mock_nick) { "op1" }
  let(:mock_op) { ops_builder.build_op(mock_nick, mock_user_settings) }
  let(:mock_message) { double("Cinch::Message", user: mock_op.irc_user) }
  let(:mock_user_settings) { nil }
  let(:settings_command) { Zabbirc::Irc::SettingsCommand.new ops_builder.ops, mock_message, cmd }


  describe "#show_settings" do
    let(:mock_user_settings) { {primary_channel: "#channel-1", events_priority: "high", notify: false } }
    let(:expected_msg) { "#{mock_nick}: Default settings: notify: false, notify_recoveries: true, primary_channel: #channel-1, events_priority: high" }
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

    context "group specific" do
      let(:group1) { double "HostGroup", id: 1, name: "Group1" }
      let(:group2) { double "HostGroup", id: 2, name: "Group2" }
      let(:groups) { [group1, group2] }
      before do
        allow(Zabbirc::Zabbix::HostGroup).to receive(:get) { groups }
        allow(Zabbirc::Zabbix::HostGroup).to receive(:get).with(hash_including(search: { name: anything })) do |params|
          groups.select{|g| g.name =~ /#{params[:search][:name]}/ }
        end
      end

      shared_examples "set_group_setting" do |key, value, expected_setting_value|
        let(:expected_msg) { "#{mock_nick}: setting `#{key}` has been set to `#{expected_setting_value}` for host groups: #{affected_host_group.name}" }
        let(:cmd) { "set #{key} #{value} hostgroups #{affected_host_group.name}"}
        it "should set #{key} setting to #{value} for host group" do
          old_global_value = mock_op.setting.get(key)

          expect(mock_message).to receive(:reply).with(expected_msg)
          settings_command.run
          expect(mock_op.setting.get(key, host_group_id: affected_host_group.id)).to eq expected_setting_value

          expect(mock_op.setting.get(key)).to eq old_global_value
        end
      end

      shared_examples "set_all_groups_setting" do |key, value, expected_setting_value|
        let(:settings_command1) { Zabbirc::Irc::SettingsCommand.new ops_builder.ops, mock_message, cmd1 }
        let(:settings_command2) { Zabbirc::Irc::SettingsCommand.new ops_builder.ops, mock_message, cmd2 }

        let!(:old_global_value) { mock_op.setting.get(key, host_group_id: affected_host_group.id) }
        let(:expected_msg1) { "#{mock_nick}: setting `#{key}` has been set to `#{expected_setting_value}` for host groups: #{affected_host_group.name}" }
        let(:expected_msg2) { "#{mock_nick}: setting `#{key}` has been set to `#{old_global_value}` for all host groups" }
        let(:cmd1) { "set #{key} #{value} hostgroups #{affected_host_group.name}"}
        let(:cmd2) { "set #{key} #{old_global_value} hostgroups-all"}
        it "should set #{key} setting to #{value} for all host groups" do
          # sets host group specific setting
          expect(mock_message).to receive(:reply).with(expected_msg1)
          settings_command1.run
          expect(mock_op.setting.get(key, host_group_id: affected_host_group.id)).to eq expected_setting_value
          expect(mock_op.setting.get(key)).to eq old_global_value

          expect(mock_message).to receive(:reply).with(expected_msg2)
          settings_command2.run
          expect(mock_op.setting.get(key, host_group_id: affected_host_group.id)).to eq old_global_value
          expect(mock_op.setting.get(key)).to eq old_global_value
        end
      end

      it_should_behave_like "set_group_setting", "notify", "false", false do
        let(:affected_host_group) { group1 }
      end

      it_should_behave_like "set_group_setting", "events_priority", "high", :high do
        let(:affected_host_group) { group1 }
      end

      it_should_behave_like "set_group_setting", "events_priority", "5", :disaster do
        let(:affected_host_group) { group1 }
      end

      it_should_behave_like "set_all_groups_setting", "notify", "false", false do
        let(:affected_host_group) { group1 }
      end

      it_should_behave_like "set_all_groups_setting", "events_priority", "high", :high do
        let(:affected_host_group) { group1 }
      end

      it_should_behave_like "set_all_groups_setting", "events_priority", "5", :disaster do
        let(:affected_host_group) { group1 }
      end

    end
  end
end