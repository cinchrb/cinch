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

    # @return [Boolean]
    attr_reader :strip_colors

    # @return [ThreadGroup]
    # @api private
    attr_reader :thread_group

    # @param [Bot] bot
    # @param [Symbol] event
    # @param [Pattern] pattern
    # @param [Hash] options
    # @option options [Symbol] :group (nil) Match group the h belongs
    #   to.
    # @option options [Boolean] :execute_in_callback (false) Whether
    #   to execute the handler in an instance of {Callback}
    # @option options [Boolean] :strip_colors (false) Strip colors
    #   from message before attemping match
    # @option options [Array] :args ([]) Additional arguments to pass
    #   to the block
    def initialize(bot, event, pattern, options = {}, &block)
      options              = {
        :group => nil,
        :execute_in_callback => false,
        :strip_colors => false,
        :args => []
      }.merge(options)
      @bot                 = bot
      @event               = event
      @pattern             = pattern
      @group               = options[:group]
      @execute_in_callback = options[:execute_in_callback]
      @strip_colors        = options[:strip_colors]
      @args                = options[:args]
      @block               = block

      @thread_group = ThreadGroup.new
    end

    # Unregisters the handler.
    #
    # @return [void]
    def unregister
      @bot.handlers.unregister(self)
    end

    # Stops execution of the handler. This means stopping and killing
    # all associated threads.
    #
    # @return [void]
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

    # Executes the handler.
    #
    # @param [Message] message Message that caused the invocation
    # @param [Array] captures Capture groups of the pattern that are
    #   being passed as arguments
    # @return [Thread]
    def call(message, captures, arguments)
      bargs = captures + arguments

      thread = Thread.new {
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

      @thread_group.add(thread)
      thread
    end

    # @return [String]
    def to_s
      # TODO maybe add the number of running threads to the output?
      "#<Cinch::Handler @event=#{@event.inspect} pattern=#{@pattern.inspect}>"
    end
  end
end
