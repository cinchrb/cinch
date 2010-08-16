module Cinch
  module Logger
    class FormattedLogger
      COLORS = {
        :reset => "\e[0m",
        :bold => "\e[1m",
        :red => "\e[31m",
        :green => "\e[32m",
        :yellow => "\e[33m",
        :blue => "\e[34m",
      }

      def initialize(output)
        @output = output
        @mutex = Mutex.new
      end

      # @return [void]
      def debug(messages)
        log(messages, :debug)
      end

      # @api private
      # @return [void]
      def log(messages, kind = :generic)
        @mutex.synchronize do
          messages = [messages].flatten.map {|s| s.chomp}
          # message = message.to_s.chomp # don't want to tinker with the original string

          messages.each do |message|
            if kind == :debug
              prefix = colorize("!! ", :yellow)
              message = prefix + message
            else
              pre, msg = message.split(" :", 2)
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

              message = prefix + pre_parts.join(" ")
              message << colorize(" :#{msg}", :yellow) if msg
            end
            @output.puts message.encode
          end
        end
      end

      # @api private
      # @param [String] text text to colorize
      # @param [Array<Symbol>] codes array of colors to apply
      # @return [String] colorized string
      def colorize(text, *codes)
        COLORS.values_at(*codes).join + text + COLORS[:reset]
      end

      # @api private
      def log_exception(e)
        lines = ["#{e.backtrace.first}: #{e.message} (#{e.class})"]
        lines.concat e.backtrace[1..-1].map {|s| "\t" + s}
        debug(lines)
      end
    end
  end
end
