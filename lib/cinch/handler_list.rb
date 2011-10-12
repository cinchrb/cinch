require "thread"
require "cinch/cached_list"

module Cinch
  # @since 1.2.0
  class HandlerList
    include Enumerable

    def initialize
      @handlers = Hash.new {|h,k| h[k] = []}
      @mutex = Mutex.new
    end

    def register(handler)
      @mutex.synchronize do
        @handlers[handler.event] << handler
      end
    end

    # @param [Handler, Array<Handler>] *handlers The handlers to unregister
    # @return [void]
    # @see Handler#unregister
    def unregister(*handlers)
      @mutex.synchronize do
        handlers.each do |handler|
          @handlers[handler.event].delete(handler)
        end
      end
    end

    def find(type, msg = nil)
      if handlers = @handlers[type]
        if msg.nil?
          return handlers
        end

        handlers.select { |handler|
          msg.match(handler.pattern.to_r(msg), type)
        }
      end
    end

    # @param [Symbol] event The event type
    # @param [Message, nil] msg The message which is responsible for
    #   and attached to the event, or nil.
    # @param [Array] *arguments A list of additional arguments to pass
    #   to event handlers
    # @return [void]
    def dispatch(event, msg = nil, *arguments)
      if handlers = find(event, msg)
        handlers.each do |handler|
          # calling Message#match multiple times is not a problem
          # because we cache the result
          if msg
            captures = msg.match(handler.pattern.to_r(msg), event).captures
          else
            captures = []
          end

          handler.call(msg, captures, arguments)
        end
      end
    end

    # @yield [handler] Yields all registered handlers
    # @yieldparam [Handler] handler
    # @return [void]
    def each(&block)
      @handlers.values.flatten.each(&block)
    end
  end
end
