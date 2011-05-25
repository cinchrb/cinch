module Cinch
  # @since 1.2.0
  class Timer
    # @return [Bot]
    attr_reader :bot
    # @return [Number] The interval (in seconds) of the timer
    attr_accessor :interval
    # @return [Boolean] If true, each invocation will be
    #   executed in a thread of its own.
    attr_accessor :threaded
    # @return [Proc]
    attr_reader :block
    # @return [Boolean]
    attr_reader :started
    alias_method :threaded?, :threaded
    alias_method :started?, :started

    # @param [Bot] bot The instance of {Bot} the timer is associated
    #   with
    # @param [Number] interval The interval (in seconds) of the timer
    # @param [Boolean] threaded If true, each invocation will be
    #   executed in a thread of its own.
    def initialize(bot, interval, threaded = true, &block)
      @bot      = bot
      @interval = interval
      @threaded = threaded
      @block    = block

      @started = false
      @thread  = nil
    end

    # @return [Boolean]
    def stopped?
      !@started
    end

    # Start the timer
    #
    # @return [void]
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

    # Stop the timer
    #
    # @return [void]
    def stop
      @thread.kill
      @started = false
    end
  end
end
