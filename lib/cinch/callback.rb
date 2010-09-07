module Cinch
  # @api private
  class Callback
    include Helpers

    attr_reader :bot
    def initialize(bot)
      @bot = bot
    end

    def synchronize(*args)
      @bot.synchronize(*args)
    end
  end
end
