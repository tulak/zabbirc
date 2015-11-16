describe Zabbirc::Irc::MaintenanceCommand do
  let(:ops_builder) { Zabbirc::OpsBuilder.new }
  let(:mock_nick) { "op1" }
  let(:mock_op) { ops_builder.build_op(mock_nick, mock_user_settings) }
  let(:mock_message) { double("Cinch::Message", user: mock_op.irc_user) }
  let(:mock_user_settings) { nil }
  let(:maintenance_command) { Zabbirc::Irc::MaintenanceCommand.new ops_builder.ops, mock_message, cmd }


  describe "list maintenances" do
    let(:cmd) { "" }

    before do
      allow(Zabbirc::Zabbix::Maintenance).to receive(:get).and_return(maintenances)
    end

    context "no active maintenances" do
      let(:maintenances) { [] }
      let(:expected_message) { "#{mock_nick}: No active maintenances at this moment." }

      it "should print active maintenances" do
        expect(mock_message).to receive(:reply).with(expected_message)
        maintenance_command.run
      end
    end

    context "active maintenances exist" do
      let(:maint1) { double("Maintenance", label: "maint 1 label", active?: true) }
      let(:maint2) { double("Maintenance", label: "maint 2 label", active?: true) }
      let(:maintenances) { [maint1, maint2] }

      let(:expected_message) do
        maintenances.collect do |maintenance|
          "#{mock_nick}: #{maintenance.label}"
        end.join("\n")
      end


      it "should print active maintenances" do
        expect(mock_message).to receive(:reply).with(expected_message)
        maintenance_command.run
      end
    end
  end

  describe "create maintenance" do
    let(:host1) { double("Host", id: 1, name: "Host1") }
    let(:host2) { double("Host", id: 2, name: "Host2") }
    let(:hosts) { [host1, host2] }

    let(:host_group1) { double("HostGroup", id: 11, name: "HostGroup1") }
    let(:host_group2) { double("HostGroup", id: 12, name: "HostGroup2") }
    let(:host_groups) { [host_group1, host_group2] }

    let(:duration) { "1h30m" }
    let(:duration_int) { (1.hour + 30.minutes).to_i }
    let(:reason) { "some reason" }

    let(:created_maintenance) { double("Maintenance", label: "maintenance label", active_since: Time.now, active_till: Time.now) }

    before do
      allow(Zabbirc::Zabbix::Maintenance).to receive(:create).with(any_args).and_return(true)
      allow(Zabbirc::Zabbix::Host).to receive(:get).with(hash_including(search: { name: anything })) do |params|
        hosts.select{|g| g.name =~ /#{params[:search][:name]}/ }
      end
      allow(Zabbirc::Zabbix::HostGroup).to receive(:get).with(hash_including(search: { name: anything })) do |params|
        host_groups.select{|g| g.name =~ /#{params[:search][:name]}/ }
      end
      allow(Zabbirc::Zabbix::Maintenance).to receive(:find).and_return(created_maintenance)
    end

    context "hosts" do
      let(:cmd) { "'#{host1.name},#{host2.name}' #{duration} #{reason}" }
      it "should create maintenance" do
        expect(Zabbirc::Zabbix::Maintenance).to receive(:create).with(duration: duration_int, host_ids: hosts.collect(&:id), name: reason)
        expect(mock_message).to receive(:reply)
        maintenance_command.run
      end

      context "without data collection" do
        let(:cmd) { "no-data '#{host1.name},#{host2.name}' #{duration} #{reason}" }
        it "should create maintenance" do
          expect(Zabbirc::Zabbix::Maintenance).to receive(:create).with(duration: duration_int, host_ids: hosts.collect(&:id), name: reason, without_data_collection: true)
          expect(mock_message).to receive(:reply)
          maintenance_command.run
        end
      end
    end

    context "host groups" do
      let(:cmd) { "hostgroups '#{host_group1.name},#{host_group2.name}' #{duration} #{reason}" }
      it "should create maintenance" do
        expect(Zabbirc::Zabbix::Maintenance).to receive(:create).with(duration: duration_int, host_group_ids: host_groups.collect(&:id), name: reason)
        expect(mock_message).to receive(:reply)
        maintenance_command.run
      end

      context "without data collection" do
        let(:cmd) { "no-data hostgroups '#{host_group1.name},#{host_group2.name}' #{duration} #{reason}" }
        it "should create maintenance" do
          expect(Zabbirc::Zabbix::Maintenance).to receive(:create).with(duration: duration_int, host_group_ids: host_groups.collect(&:id), name: reason, without_data_collection: true)
          expect(mock_message).to receive(:reply)
          maintenance_command.run
        end
      end
    end


  end
end