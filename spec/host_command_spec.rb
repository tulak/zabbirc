describe Zabbirc::Irc::HostCommand do
  let(:ops_builder) { Zabbirc::OpsBuilder.new }
  let(:mock_nick) { "op1" }
  let(:mock_op) { ops_builder.build_op(mock_nick, mock_user_settings) }
  let(:mock_message) { double("Cinch::Message", user: mock_op.irc_user) }
  let(:mock_user_settings) { nil }
  let(:host_command) { Zabbirc::Irc::HostCommand.new ops_builder.ops, mock_message, cmd }

  describe "#host_status" do
    before do
      allow(Zabbirc::Zabbix::Host).to receive(:get).and_return(hosts)
    end

    context "reporting" do
      before do
        allow(Zabbirc::Zabbix::Trigger).to receive(:get).and_return(problem_triggers)
      end
      let(:cmd) { "status #{host.name}" }
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
          host_command.run
        end
      end

      context "ok trigger" do
        let(:problem_triggers) { [] }
        let(:expected_msg) { "#{mock_nick}: Host: #{host.name} - status: OK" }
        it "should report problem" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          host_command.run
        end
      end
    end # context reporting

    context "host identification" do
      let(:cmd) { "status #{host_name_value}" }
      context "no hosts" do
        let(:hosts) { [] }
        let(:host_name_value) { "undefined_host_name" }
        it "should not found host" do
          expect(mock_message).to receive(:reply).with("#{mock_nick}: Host not found `#{host_name_value}`")
          host_command.run
        end
      end

      context "2 - 10 hosts" do
        let(:host1) { double "Host1", id: 1, name: "host-1" }
        let(:host2) { double "Host2", id: 2, name: "host-2" }
        let(:hosts) { [host1, host2] }
        let(:host_name_value) { "host" }
        let(:expected_msg) { "#{mock_nick}: Found #{hosts.size} hosts: #{hosts.collect(&:name).join(', ')}. Be more specific" }
        it "should print host names" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          host_command.run
        end
      end

      context "more than 10 hosts" do
        let(:hosts) { double "HostsArray", size: 11 }
        let(:host_name_value) { "host" }
        let(:expected_msg) { "#{mock_nick}: Found #{hosts.size} Be more specific" }
        it "should print host names" do
          expect(mock_message).to receive(:reply).with(expected_msg)
          host_command.run
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

    let(:cmd) { "latest Host1" }
    it "should print latest events" do
      expect(mock_message).to receive(:reply).with(expected_msg)
      host_command.run
    end
  end
end