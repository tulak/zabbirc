describe Zabbirc::Irc::HostCommand do
  let(:ops_builder) { Zabbirc::OpsBuilder.new }
  let(:mock_nick) { "op1" }
  let(:mock_op) { ops_builder.build_op(mock_nick, mock_user_settings) }
  let(:mock_message) { double("Cinch::Message", user: mock_op.irc_user) }
  let(:mock_user_settings) { nil }
  let(:event_command) { Zabbirc::Irc::EventCommand.new ops_builder.ops, mock_message, cmd }


  describe "events", focus: true do
    context "no host arg" do
      let(:cmd) { "events" }
      let(:event1) { double "Event", label: "Event 1 label", priority: Zabbirc::Priority.new(:high) }
      let(:event2) { double "Event", label: "Event 2 label", priority: Zabbirc::Priority.new(:high) }
      let(:events) { [event1, event2] }

      let(:expected_msg) do
        events.collect do |event|
          "#{mock_nick}: #{event.label}"
        end.join("\n")
      end
      before do
        allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return(events)
      end

      it "should report latest events" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        event_command.run
      end
    end

    context "with priority arg" do
      let(:priority) { Zabbirc::Priority.new "high" }
      let(:cmd) { "events #{priority}" }
      let(:event_high) { double "Event", label: "Event High label", priority: Zabbirc::Priority.new(:high) }
      let(:event_average) { double "Event", label: "Event Average label", priority: Zabbirc::Priority.new(:average) }
      let(:events) { [event_high, event_average] }
      let(:expected_events) { events.select{|e| e.priority == priority } }

      let(:expected_msg) do
        expected_events.collect do |event|
          "#{mock_nick}: #{event.label}"
        end.join("\n")
      end
      before do
        allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return(events)
      end

      it "should report latest events" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        event_command.run
      end
    end


    context "with priority and host arg" do
      let(:host) { "host1" }
      let(:priority) { Zabbirc::Priority.new "high" }
      let(:cmd) { "events #{priority} #{host}" }
      let(:event_high_good_host) { double "Event", label: "Event High label", priority: Zabbirc::Priority.new(:high) }
      let(:event_high_bad_host) { double "Event", label: "Event High label", priority: Zabbirc::Priority.new(:high) }
      let(:event_average) { double "Event", label: "Event Average label", priority: Zabbirc::Priority.new(:average) }
      let(:events) { [event_high_good_host, event_high_bad_host, event_average] }
      let(:expected_events) { events.select{|e| e.priority == priority }.select{|e| e.any_host_matches? host } }

      let(:expected_msg) do
        expected_events.collect do |event|
          "#{mock_nick}: #{event.label}"
        end.join("\n")
      end
      before do
        allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return(events)
        allow(event_high_good_host).to receive(:any_host_matches?).with(/#{host}/).and_return(true)
        allow(event_high_bad_host).to receive(:any_host_matches?).with(/#{host}/).and_return(false)
      end

      it "should report latest events" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        event_command.run
      end
    end
  end

  describe "ack" do
    let(:event) { double "Event", eventid: 1, label: "Event to ack" }
    let(:message) { "ack message" }
    let(:cmd) { "ack #{short_event_id} #{message}" }

    context "bad short_event_id" do
      let(:short_event_id) { "XXX" }
      let(:expected_msg) { "#{mock_nick}: Bad event id `#{short_event_id}`" }

      it "should report error message" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        event_command.run
      end
    end

    context "good short_event_id" do
      let(:short_event_id) { Zabbirc.events_id_shortener.get_shorten_id(event.eventid) }
      let(:expected_msg) { "#{mock_nick}: Event `#{event.label}` acknowledged with message: #{message}" }
      before do
        allow(Zabbirc::Zabbix::Event).to receive(:find).with(event.eventid, anything).and_return(event)
        allow(event).to receive(:acknowledge).and_return(true)
      end

      it "should acknowledge event" do
        expect(mock_message).to receive(:reply).with(expected_msg)
        event_command.run
      end
    end
  end

end