module Cinch
  # Class used for encapsulating handlers to prevent them from
  # overwriting instance variables in {Bot}
  #
  # @api private
  class Callback
    include Helpers

    # @return [Bot]
    attr_reader :bot
    def initialize(bot)
      @bot = bot
    end

    # (see Bot#synchronize)
    def synchronize(name, &block)
      @bot.synchronize(name, &block)
    end
  end
end
