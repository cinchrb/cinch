require "cinch/logger"
module Cinch
  class Logger
    # This logger logs all incoming messages in the format of zcbot.
    # All other debug output (outgoing messages, exceptions, ...) will
    # silently be dropped. The sole purpose of this logger is to
    # produce logs parseable by pisg (with the zcbot formatter) to
    # create channel statistics..
    class ZcbotLogger < Cinch::Logger
      # (see Logger#log)
      def log(messages, event, level = event)
        return if event != :incoming
        super
      end

      private
      def format_incoming(message)
        Time.now.strftime("%m/%d/%Y %H:%M:%S ") + message
      end
    end
  end
end
