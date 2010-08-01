module Cinch
  class FormattedLogger
    COLORS = {
      :reset => "\e[0m",
      :bold => "\e[1m",
      :red => "\e[31m",
      :green => "\e[32m",
      :yellow => "\e[33m",
      :blue => "\e[34m",
    }

    class << self
      # @return [void]
      def debug(message)
        log(message, :debug)
      end

      # @api private
      # @return [void]
      def log(message, kind = :generic)
        message = message.to_s.chomp # don't want to tinker with the original string
        unless $stdout.tty?
          $stderr.puts message
          return
        end

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
        $stderr.puts message
      end

      # @api private
      # @param [String] text text to colorize
      # @param [Array<Symbol>] codes array of colors to apply
      # @return [String] colorized string
      def colorize(text, *codes)
        COLORS.values_at(*codes).join + text + COLORS[:reset]
      end
    end
  end
end
