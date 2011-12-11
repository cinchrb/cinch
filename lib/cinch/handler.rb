module Cinch
  # @since 2.0.0
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
    # @return [Symbol]
    attr_reader :group
    # @return [ThreadGroup]
    # @api private
    attr_reader :thread_group
    def initialize(bot, event, pattern, options = {}, &block)
      options = {:group => nil, :execute_in_callback => false, :args => []}.merge(options)
      @bot = bot
      @event = event
      @pattern = pattern
      @group = options[:group]
      @execute_in_callback = options[:execute_in_callback]
      @args = options[:args]
      @block = block

      @thread_group = ThreadGroup.new
    end

    def unregister
      @bot.handlers.unregister(self)
    end

    def stop
      @bot.loggers.debug "[Stopping handler] Stopping all threads of handler #{self}: #{@thread_group.list.size} threads..."
      @thread_group.list.each do |thread|
        Thread.new do
          @bot.loggers.debug "[Ending thread] Waiting 10 seconds for #{thread} to finish..."
          thread.join(10)
          @bot.loggers.debug "[Killing thread] Killing #{thread}"
          thread.kill
        end
      end
    end

    def call(message, captures, arguments)
      bargs = captures + arguments

      @thread_group.add Thread.new {
        @bot.loggers.debug "[New thread] For #{self}: #{Thread.current} -- #{@thread_group.list.size} in total."

        begin
          if @execute_in_callback
            @bot.callback.instance_exec(message, *@args, *bargs, &@block)
          else
            @block.call(message, *@args, *bargs)
          end
        rescue => e
          @bot.loggers.exception(e)
        ensure
          @bot.loggers.debug "[Thread done] For #{self}: #{Thread.current} -- #{@thread_group.list.size - 1} remaining."
        end
      }
    end

    def to_s
      "#<Cinch::Handler @event=#{@event.inspect} pattern=#{@pattern.inspect}>"
    end
  end
end
