module Cinch
  # @since 1.2.0
  class Handler
    # @return [Bot]
    attr_reader :bot
    # @return [Symbol]
    attr_reader :event
    # @return [Pattern]
    attr_reader :pattern
    # @return [Array]
    attr_reader :args
    # @return [Proc]
    attr_reader :block
    # @return [Array<Thread>]
    # @api private
    attr_reader :threads
    def initialize(bot, event, pattern, args = [], &block)
      @bot = bot
      @event = event
      @pattern = pattern
      @args = args
      @block = block

      @threads = []
    end

    def unregister
      @bot.handlers.unregister(self)
    end

    def stop
      @bot.loggers.debug "[Stopping handler] Stopping all threads of handler #{self}: #{@threads.size} threads..."
      @threads.each do |thread|
        @bot.loggers.debug "[Ending thread] Waiting 10 seconds for #{thread} to finish..."
        thread.join(10)
        @bot.loggers.debug "[Killing thread] Killing #{thread}"
        thread.kill
      end
    end

    def call(message, captures, arguments)
      bargs = captures + arguments

      @threads << Thread.new do
        @bot.loggers.debug "[New thread] For #{self}: #{Thread.current}"

        begin
          catch(:halt) do
            @bot.callback.instance_exec(message, *@args, *bargs, &@block)
          end
        rescue => e
          @bot.loggers.exception(e)
        ensure
          @threads.delete Thread.current
          @bot.loggers.debug "[Thread done] For #{self}: #{Thread.current} -- #{@threads.size} remaining."
        end
      end
    end

    def to_s
      "#<Cinch::Handler @event=#{@event.inspect} pattern=#{@pattern.inspect}>"
    end
  end
end
