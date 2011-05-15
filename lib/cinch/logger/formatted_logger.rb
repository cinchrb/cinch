require "cinch/logger/logger"
module Cinch
  module Logger
    # A formatted logger that will colorize individual parts of IRC
    # messages.
    class FormattedLogger < Cinch::Logger::Logger
      COLORS = {
        :reset => "\e[0m",
        :bold => "\e[1m",
        :red => "\e[31m",
        :green => "\e[32m",
        :yellow => "\e[33m",
        :blue => "\e[34m",
      }

      # @param [IO] output An IO to log to.
      def initialize(output = STDERR)
        @output = output
        @mutex = Mutex.new
      end

      # (see Logger::Logger#debug)
      def debug(messages)
        log(messages, :debug)
      end

      # (see Logger::Logger#log)
      def log(messages, kind = :generic)
        @mutex.synchronize do
          messages = [messages].flatten.map {|s| s.to_s.chomp}
          messages.each do |msg|
            next if msg.empty?
            message = Time.now.strftime("[%Y/%m/%d %H:%M:%S.%L] ")
            if kind == :debug
              prefix = colorize("!! ", :yellow)
              message << prefix + msg
            else
              pre, msg = msg.split(" :", 2)
              pre_parts = pre.split(" ")

              if kind == :incoming
                prefix = colorize(">> ", :green)

                if pre_parts.size == 1
                  pre_parts[0] = colorize(pre_parts[0], :bold)
                else
                  pre_parts[0] = colorize(pre_parts[0], :blue)
                  pre_parts[1] = colorize(pre_parts[1], :bold)
                end

              elsif kind == :outgoing
                prefix = colorize("<< ", :red)
                pre_parts[0] = colorize(pre_parts[0], :bold)
              end

              message << prefix + pre_parts.join(" ")
              message << colorize(" :#{msg}", :yellow) if msg
            end
            @output.puts message.encode("locale", {:invalid => :replace, :undef => :replace})
          end
        end
      end

      # @api private
      # @param [String] text text to colorize
      # @param [Array<Symbol>] codes array of colors to apply
      # @return [String] colorized string
      def colorize(text, *codes)
        return text unless @output.tty?
        COLORS.values_at(*codes).join + text + COLORS[:reset]
      end

      # (see Logger::Logger#log_exception)
      def log_exception(e)
        lines = ["#{e.backtrace.first}: #{e.message} (#{e.class})"]
        lines.concat e.backtrace[1..-1].map {|s| "\t" + s}
        debug(lines)
      end
    end
  end
end
