require "cinch/logger/logger"
module Cinch
  module Logger
    # This logger logs all incoming messages in the format of zcbot.
    # All other debug output (outgoing messages, exceptions, ...) will
    # silently be dropped. The sole purpose of this logger is to
    # produce logs parseable by pisg (with the zcbot formatter) to
    # create channel statistics..
    class ZcbotLogger < Cinch::Logger::Logger
      # @param [IO] output An IO to log to.
      def initialize(output = STDERR)
        @output = output
        @mutex = Mutex.new
      end

      # (see Logger::Logger#debug)
      def debug(messages)
      end

      # (see Logger::Logger#log)
      def log(messages, kind = :generic)
        return if kind != :incoming

        @mutex.synchronize do
          messages = [messages].flatten.map {|s| s.to_s.chomp}
          messages.each do |msg|
            # working around a bug in jruby 1.6.0.RC1
            destination_encoding = Encoding.find("locale")
            @output.puts Time.now.strftime("%m/%d/%Y %H:%M:%S ") + msg.encode(destination_encoding, {:invalid => :replace, :undef => :replace})
          end
        end
      end

      # (see Logger::Logger#log_exception)
      def log_exception(e)
      end
    end
  end
end
