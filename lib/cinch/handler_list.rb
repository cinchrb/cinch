require "thread"
require "set"
require "cinch/cached_list"

module Cinch
  # @since 2.0.0
  class HandlerList
    include Enumerable

    def initialize
      @handlers = Hash.new {|h,k| h[k] = []}
      @mutex = Mutex.new
    end

    def register(handler)
      @mutex.synchronize do
        handler.bot.loggers.debug "[on handler] Registering handler with pattern `#{handler.pattern.inspect}`, reacting on `#{handler.event}`"
        @handlers[handler.event] << handler
      end
    end

    # @param [Handler, Array<Handler>] handlers The handlers to unregister
    # @return [void]
    # @see Handler#unregister
    def unregister(*handlers)
      @mutex.synchronize do
        handlers.each do |handler|
          @handlers[handler.event].delete(handler)
        end
      end
    end

    # @api private
    # @return [Array<Handler>]
    def find(type, msg = nil)
      if handlers = @handlers[type]
        if msg.nil?
          return handlers
        end

        handlers = handlers.select { |handler|
          msg.match(handler.pattern.to_r(msg), type, handler.strip_colors)
        }.group_by {|handler| handler.group}

        handlers.values_at(*(handlers.keys - [nil])).map(&:first) + (handlers[nil] || [])
      end
    end

    # @param [Symbol] event The event type
    # @param [Message, nil] msg The message which is responsible for
    #   and attached to the event, or nil.
    # @param [Array] arguments A list of additional arguments to pass
    #   to event handlers
    # @return [Array<Thread>]
    def dispatch(event, msg = nil, *arguments)
      threads = []

      if handlers = find(event, msg)
        already_run = Set.new
        handlers.each do |handler|
          next if already_run.include?(handler.block)
          already_run << handler.block
          # calling Message#match multiple times is not a problem
          # because we cache the result
          if msg
            captures = msg.match(handler.pattern.to_r(msg), event, handler.strip_colors).captures
          else
            captures = []
          end

          threads << handler.call(msg, captures, arguments)
        end
      end

      threads
    end

    # @yield [handler] Yields all registered handlers
    # @yieldparam [Handler] handler
    # @return [void]
    def each(&block)
      @handlers.values.flatten.each(&block)
    end

    # @api private
    def stop_all
      each { |h| h.stop }
    end
  end
end
