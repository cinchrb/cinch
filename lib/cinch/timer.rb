module Cinch
  class Timer
    attr_reader :bot
    attr_reader :interval
    attr_accessor :threaded
    attr_reader :block
    alias_method :threaded?, :threaded

    def initialize(bot, interval, threaded = true, &block)
      @bot      = bot
      @interval = interval
      @threaded = threaded
      @block    = block

      @started = false
      @thread  = nil
    end

    def started?
      @started
    end

    def stopped?
      !@started
    end

    def start
      @thread = Thread.new do
        loop do
          sleep @interval
          if threaded?
            Thread.new do
              rescue_exception do
                @block.call
              end
            end
          else
            rescue_exception do
              @block.call
            end
          end
        end
      end

      @started = true
    end

    def stop
      @thread.kill
      @started = false
    end

    private
    def rescue_exception
      begin
        yield
      rescue => e
        @bot.logger.log_exception(e)
      end
    end
  end
end
