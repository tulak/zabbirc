describe Zabbirc::Irc::Plugins::Events do
  include Cinch::Test

  let(:service) { Zabbirc::ServiceMock.new Zabbirc::Irc::Plugins::Events }

  context "no last events" do
    before do
      allow(Zabbirc::Zabbix::Event).to receive(:recent).and_return([])
    end

    it do
      m = make_message(service.cinch_bot, "!events", nick: "op1")
      # expect(m).to receive(:reply).once
      replies = get_replies m
      binding.pry
      # expect(replies.collect(&:text)).to eq ["op1: No last events"]
    end
  end
end