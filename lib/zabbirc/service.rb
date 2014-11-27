require 'cinch'

module Zabbirc
  class Service
    attr_reader :cinch_bot
    attr_reader :ops, :ops_service
    attr_reader :running

    def initialize
      @semaphores_mutex = Mutex.new
      @semaphores       = Hash.new { |h, k| h[k] = Mutex.new }
      @ops = OpList.new
      @running = false

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

    def start join=true
      return if @running
      @running = true
      @cinch_bot_thread = Thread.new do
        begin
          @cinch_bot.start
        rescue => e
          Zabbirc.logger.fatal "Cinch bot start error: #{e}"
        end
      end

      @controll_thread = Thread.new do
        begin
          sleep
        rescue StopError
          pre_stop_script
          @ops_service.stop
          @events_service.stop

          Zabbirc.logger.info "Stopping ops service: #{@ops_service.join}"
          Zabbirc.logger.info "Stopping events service: #{@events_service.join}"

          @cinch_bot.quit
        ensure
          @running = false
        end
      end

      @ops_service.start
      @events_service.start

      @cinch_bot_thread.join if join
    end

    def pre_stop_script
      @ops.dump_settings
    rescue => e
      Zabbirc.logger.error "Exception `#{e}` while running pre_stop_script"
    end

    def stop
      @controll_thread.raise StopError
    end

    def join
      @cinch_bot_thread.join
    end
  end
end