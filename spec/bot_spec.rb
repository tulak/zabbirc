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
      shorten_id = Zabbirc.events_id_shortener.get_shorten_id event.id
      expect(mock_message).to receive(:reply).with("#{mock_nick}: Event `#{event.label}` acknowledged with message: #{message}")
      bot.acknowledge_event mock_message, shorten_id, message
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
end