module Cinch
  # @api private
  class Callback
    attr_reader :bot

    def initialize(block, args, msg, bot)
      @block, @args, @msg, @bot = block, args, msg, bot
    end

    # @return [Message]
    def message
      @msg
    end

    # @return [void]
    def call(*bargs)
      instance_exec(*@args, *bargs, &@block)
    end

    # Forwards method calls to the current message and bot instance.
    def method_missing(m, *args, &blk)
      if @msg.respond_to?(m)
        @msg.__send__(m, *args, &blk)
      elsif @bot.respond_to?(m)
        @bot.__send__(m, *args, &blk)
      else
        super
      end
    end
  end
end
