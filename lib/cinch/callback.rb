module Cinch
  # @api private
  class Callback
    include Helpers

    attr_reader :bot
    def initialize(bot)
      @bot = bot
    end

    # @param (see Bot#synchronize)
    # @yield
    # @return (see Bot#synchronize)
    # @see Bot#synchronize
    def synchronize(*args, &block)
      @bot.synchronize(*args, &block)
    end
  end
end
