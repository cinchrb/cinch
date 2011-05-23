module Cinch
  # @since 1.2.0
  class Handler
    attr_reader :bot
    attr_reader :event
    attr_reader :pattern
    attr_reader :args
    attr_reader :block
    # @return [Array<Thread>]
    # @api private
    attr_reader :threads
    def initialize(bot, event, pattern, args, block)
      @bot = bot
      @event = event
      @pattern = pattern
      @args = args
      @block = block

      @threads = []
    end

    def unregister
      @bot.unregister_handler(self)
    end

    def stop
      @threads.each do |thread|
        thread.join(10)
        thread.kill
      end
    end

    def call(message, captures, arguments)
      bargs = captures + arguments
      @threads << Thread.new do
        begin
          catch(:halt) do
            @bot.callback.instance_exec(message, *@args, *bargs, &@block)
          end
        rescue => e
          @bot.logger.log_exception(e)
        ensure
          @threads.delete Thread.current
        end
      end
    end
  end
end
