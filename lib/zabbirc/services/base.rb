module Zabbirc
  module Services
    class Base
      LOOP_SLEEP = 10
      attr_reader :quiting, :running

      def initialize service, cinch_bot
        @service   = service
        @cinch_bot = cinch_bot
        @quiting   = false
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
            until @quiting
              @running = true
              iterate
              sleep LOOP_SLEEP
            end
          rescue => e
            main_thread.raise e
          ensure
            @quiting = false
            @running = false
          end
        end
      end

      def stop
        @quiting = true
      end


    end
  end
end
