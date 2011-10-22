require "cinch/helpers"

module Cinch
  # @since 1.2.0
  class Timer
    include Helpers

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
    # @return [Number] The remaining number of shots before this timer
    #   will stop. This value will automatically reset after
    #   restarting the timer.
    attr_accessor :shots
    alias_method :threaded?, :threaded
    alias_method :started?, :started

    # @api private
    attr_reader :thread_group

    # @param [Bot] bot The instance of {Bot} the timer is associated
    #   with
    # @option options [Number] :interval The interval (in seconds) of
    #   the timer
    # @option options [Number] :shots (Infinity) How often should the
    #   timer fire?
    # @option options [Boolean] :threaded (true) If true, each invocation will be
    #   executed in a thread of its own.
    # @option options [Boolean] :start_automatically (true) If true,
    #   the timer will automatically start after the bot finished
    #   connecting.
    # @option options [Boolean] :stop_automaticall (true) If true, the
    #   timer will automatically stop when the bot disconnects.
    def initialize(bot, options, &block)
      options = {:treaded => true, :shots => Infinity, :start_automatically => true, :stop_automatically => true}.merge(options)

      @bot        = bot
      @interval   = options[:interval].to_f
      @threaded   = options[:threaded]
      @orig_shots = options[:shots]
      # Setting @shots here so the attr_reader won't return nil
      @shots      = @orig_shots
      @block      = block

      @started = false
      @thread_group = ThreadGroup.new

      if options[:start_automatically]
        @bot.on :connect, [], self do |m, timer|
          timer.start
        end
      end

      if options[:stop_automatically]
        @bot.on :disconnect, [], self do |m, timer|
          timer.stop
        end
      end
    end

    # @return [Boolean]
    def stopped?
      !@started
    end

    # Start the timer
    #
    # @return [void]
    def start
      return if @started

      @bot.loggers.debug "[timer] Starting timer #{self}"

      @shots = @orig_shots

      @thread_group.add Thread.new {
        while @shots > 0 do
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

          @shots -= 1
        end
      }

      @started = true
    end

    # Stop the timer
    #
    # @return [void]
    def stop
      return unless @started

      @bot.loggers.debug "[timer] Stopping timer #{self}"

      @thread_group.list.each { |thread| thread.kill }
      @started = false
    end

    def to_s
      "<Cinch::Timer %s/%s shots, %ds interval, %sthreaded, %sstarted, block: %s>" % [@orig_shots - @shots, @orig_shots, @interval, @threaded ? "" : "not ", @started ? "" : "not ", @block]
    end
  end
end
