module Cinch
  class Timer
    attr_reader :bot
    attr_reader :interval
    attr_reader :options
    attr_reader :block
    def initialize(bot, interval, options = {}, &block)
      @bot      = bot
      @interval = interval
      @options  = options
      @block    = block

      @started = false
      @thread  = nil
    end

    def threaded?
      @options[:threaded]
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
