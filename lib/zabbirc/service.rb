require 'cinch'

module Zabbirc
  class Service
    attr_reader :cinch_bot
    attr_reader :ops, :ops_service

    def initialize
      @semaphores_mutex = Mutex.new
      @semaphores       = Hash.new { |h, k| h[k] = Mutex.new }
      @ops = {}

      initialize_bot

      @ops_service = Services::Ops.new self, @cinch_bot
      @events_service = Services::Events.new self, @cinch_bot
    end

    def initialize_bot
      @cinch_bot = Cinch::Bot.new do
        configure do |c|
          c.server = Zabbirc.config.irc_server
          c.channels = Zabbirc.config.irc_channels
          c.nick = "zabbirc"
          c.plugins.plugins = [Irc::Plugin]
        end
      end

      # Stores reference to this Zabbirc::Service to be available in plugins
      @cinch_bot.instance_variable_set :@zabbirc_service, self
      @cinch_bot.class_eval do
        attr_reader :zabbirc_service
      end
    end

    def synchronize(name, &block)
      # Must run the default block +/ fetch in a thread safe way in order to
      # ensure we always get the same mutex for a given name.
      semaphore = @semaphores_mutex.synchronize { @semaphores[name] }
      semaphore.synchronize(&block)
    end

    def start
      @cinch_bot_thread = Thread.new do
        begin
          @cinch_bot.start
        rescue => e
          puts "CHYBAAAAA"
          binding.pry
        end

      end


      @ops_service.start
      @events_service.start
    end

    def stop
      @ops_service.stop
      @events_service.stop

      puts "ops: #{@ops_service.join}"
      puts "events: #{@events_service.join}"

      @cinch_bot.quit
    end
  end
end