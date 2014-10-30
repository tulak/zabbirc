module Zabbirc
  module Services
    class Base
      LOOP_SLEEP = 10
      attr_reader :running

      def initialize service, cinch_bot
        @service   = service
        @cinch_bot = cinch_bot
        @running   = false
        @mutex     = Mutex.new
      end

      def synchronize
        @mutex.synchronize do
          yield
        end
      end

      def join
        slept = 0
        while slept < (LOOP_SLEEP * 2)
          return true if @running == false
          sleep 1
          slept += 1
        end
        false
      end

      def start
        main_thread = Thread.current
        @thread     = Thread.new do
          begin
            loop do
              Thread.handle_interrupt(StopError => :never) do
                @running = true
                iterate
              end
              Thread.handle_interrupt(StopError => :immediate) do
                sleep LOOP_SLEEP
              end
            end
          rescue StopError => e
            # nothing, ensure block sets the variables
          rescue => e
            main_thread.raise e
          ensure
            @running = false
          end
        end
      end

      def stop
        @thread.raise StopError
      end
    end
  end
end
