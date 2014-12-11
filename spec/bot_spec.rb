describe Zabbirc::Irc::PluginMethods do
  # let(:service) { Zabbirc::ServiceMock.new }
  let(:mock_message) { double("Cinch::Message", user: mock_user) }
  let(:mock_user) { double("Cinch::User", nick: mock_nick, login: mock_login) }
  let(:bot) { Zabbirc::MockBot.new }
  let(:mock_nick) { "op1" }
  let(:mock_login) { "op1" }
  let(:mock_user_settings) { nil }

  before do
    bot.setup_op mock_nick, mock_user_settings
  end

  describe "#acknowledge_event" do
    let(:event) { double "Event", id: 1, label: "Event 1 label" }
    let(:message) { "ack message" }
    before do
      allow(event).to receive(:acknowledge).and_return(true)
      allow(Zabbirc::Zabbix::Event).to receive(:find).and_return(event)
    end

    it "should acknowledge event" do
      expect(mock_message).to receive(:reply).with("#{mock_nick}: Event `#{event.label}` acknowledged with message: #{message}")
      bot.acknowledge_event mock_message, event.id, message
    end
  end

  describe "#host_status" do
    before do
      allow(Zabbirc::Zabbix::Host).to receive(:get).and_return(hosts)
    end

    context "reporting" do
      before do
        allow(Zabbirc::Zabbix::Trigger).to receive(:get).and_return(problem_triggers)
      end
      let(:host) { double "Host", id: 1, name: "Host-1" }
      let(:hosts) { [host] }
      let(:problem_trigger) { double "Trigger", priority: Zabbirc::Priority.new(1), label: "problem_trigger", value: 1 }
      context "problem trigger" do
        let(:problem_triggers) { [problem_trigger] }
        let(:expected_msg) do
          msg = ["#{mock_nick}: Host: #{host.name} - status: #{problem_triggers.size} problems"]
          problem_triggers.each do |trigger|
            msg << "#{mock_nick}: status: #{trigger.label}"
          end
          msg.join("\n")
        end
        it "should report problem" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          bot.host_status mock_message, host.name
        end
      end

      context "ok trigger" do
        let(:problem_triggers) { [] }
        let(:expected_msg) { "#{mock_nick}: Host: #{host.name} - status: OK" }
        it "should report problem" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          bot.host_status mock_message, host.name
        end
      end
    end # context reporting

    context "host identification" do
      context "no hosts" do
        let(:hosts) { [] }
        let(:host_name) { "undefined_host_name" }
        it "should not found host" do
          expect(mock_message).to receive(:reply).with("#{mock_nick}: Host not found `#{host_name}`")
          bot.host_status mock_message, host_name
        end
      end

      context "2 - 10 hosts" do
        let(:host1) { double "Host1", id: 1, name: "host-1" }
        let(:host2) { double "Host2", id: 2, name: "host-2" }
        let(:hosts) { [host1, host2] }
        let(:expected_msg) { "#{mock_nick}: Found #{hosts.size} hosts: #{hosts.collect(&:name).join(', ')}. Be more specific" }
        it "should print host names" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          bot.host_status mock_message, "host"
        end
      end

      context "more than 10 hosts" do
        let(:hosts) { double "HostsArray", size: 11 }
        let(:expected_msg) { "#{mock_nick}: Found #{hosts.size} Be more specific" }
        it "should print host names" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          bot.host_status mock_message, "host"
        end
      end
    end # context host identification
  end # context #host_status

  context "#host_latest" do
    let(:host) { double "Host", id: 1, name: "Host1" }
    let(:hosts) { [host] }
    let(:event1) { double "Event", label: "Event 1 label" }
    let(:events) { [event1] }
    let(:expected_msg) do
      msg = ["#{mock_nick}: Host: #{host.name} - showing last #{events.size} events"]
      events.each do |event|
        msg << "#{mock_nick}: !latest: #{event.label}"
      end
      msg.join("\n")
    end
    before do
      allow(Zabbirc::Zabbix::Host).to receive(:get).and_return(hosts)
      allow(Zabbirc::Zabbix::Event).to receive(:get).and_return(events)
    end

    it "should print latest events" do
      expect(mock_message).to receive(:reply).with(expected_msg)
      bot.host_latest mock_message, "Host1", nil
    end
  end

  describe "#list_events" do
    before do
      allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return(recent_events)
    end
    context "no last events" do
      let(:recent_events) { [] }

      it "should report no last events" do
        expect(mock_message).to receive(:reply).with("#{mock_nick}: No last events for priority `#{Zabbirc::Priority.new(0)}`")
        bot.list_events mock_message
      end
    end

    context "some last events" do
      let(:event1_information) { double "Event1", label: "Event 1 label", priority: Zabbirc::Priority.new(:information) }
      let(:event2_information) { double "Event2", label: "Event 2 label", priority: Zabbirc::Priority.new(:information) }
      let(:event3_high)        { double "Event3", label: "Event 3 label", priority: Zabbirc::Priority.new(:high) }
      let(:recent_events) { [event1_information, event2_information, event3_high] }
      let(:expected_msg) { recent_events.collect{|e| "#{mock_nick}: #{e.label}"}.join("\n") }

      before do
        recent_events.each do |e|
          allow(e).to receive(:any_host_matches?).and_return(false)
        end
      end

      it "should report all last events" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        bot.list_events mock_message
      end

      context "with high priority filtered" do
        let(:expected_msg) { [event3_high].collect{|e| "#{mock_nick}: #{e.label}"}.join("\n") }
        it "should report high priority last events" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          bot.list_events mock_message, "high"
        end
      end

      context "with host filtered" do
        let(:expected_msg) { [event1_information].collect{|e| "#{mock_nick}: #{e.label}"}.join("\n") }
        it "should report host matched last events" do
          allow(event1_information).to receive(:any_host_matches?).and_return(true  )
          expect(mock_message).to receive(:reply).with(expected_msg)
          bot.list_events mock_message, "information", "host1"
        end
      end
    end
  end

  describe "#show_settings" do
    let(:mock_user_settings) { {primary_channel: "#channel-1", events_priority: "high", notify: false } }
    let(:expected_msg) { "#{mock_nick}: notify: false, notify_recoveries: true, primary_channel: #channel-1, events_priority: high" }
    it "should show settings" do
      expect(mock_message).to receive(:reply).with(expected_msg)
      bot.show_settings mock_message
    end
  end

  describe "#set_setting" do
    shared_examples "set_setting" do |key, value, expected_setting_value|
      let(:expected_msg) { "#{mock_nick}: setting `#{key}` has been set to `#{expected_setting_value}`" }
      let(:op) { bot.get_op mock_nick }
      it "should set #{key} setting to #{value}" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        bot.set_setting mock_message, key, value
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