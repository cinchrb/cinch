require "cinch/logger"

module Cinch
  class Logger
    # @version 2.0.0
    class FormattedLogger < Logger
      # @private
      Colors = {
        :reset => "\e[0m",
        :bold => "\e[1m",
        :red => "\e[31m",
        :green => "\e[32m",
        :yellow => "\e[33m",
        :blue => "\e[34m",
        :black => "\e[30m",
        :bg_white => "\e[47m",
      }

      # (see Logger#exception)
      def exception(e)
        lines = ["#{e.backtrace.first}: #{e.message} (#{e.class})"]
        lines.concat e.backtrace[1..-1].map {|s| "\t" + s}
        log(lines, :exception, :error)
      end

      private
      def timestamp
        Time.now.strftime("[%Y/%m/%d %H:%M:%S.%L]")
      end

      # @api private
      # @param [String] text text to colorize
      # @param [Array<Symbol>] codes array of colors to apply
      # @return [String] colorized string
      def colorize(text, *codes)
        return text unless @output.tty?
        codes = Colors.values_at(*codes).join
        text = text.gsub(/#{Regexp.escape(Colors[:reset])}/, Colors[:reset] + codes)
        codes + text + Colors[:reset]
      end

      def format_general(message)
        # :print: doesn't call all of :space: so use both.
        message.gsub(/[^[:print:][:space:]]/) do |m|
          colorize(m.inspect[1..-2], :bg_white, :black)
        end
      end

      def format_debug(message)
        "%s %s %s" % [timestamp, colorize("!!", :yellow), message]
      end

      def format_warn(message)
        format_debug(message)
      end

      def format_info(message)
        "%s %s %s" % [timestamp, "II", message]
      end

      def format_incoming(message)
        pre, msg = message.split(" :", 2)
        pre_parts = pre.split(" ")

        prefix = colorize(">>", :green)

        if pre_parts.size == 1
          pre_parts[0] = colorize(pre_parts[0], :bold)
        else
          pre_parts[0] = colorize(pre_parts[0], :blue)
          pre_parts[1] = colorize(pre_parts[1], :bold)
        end

        "%s %s %s %s" % [timestamp,
                          prefix,
                          pre_parts.join(" "),
                          msg ? colorize(":#{msg}", :yellow) : ""]
      end

      def format_outgoing(message)
        pre, msg = message.split(" :", 2)
        pre_parts = pre.split(" ")

        prefix = colorize("<<", :red)
        pre_parts[0] = colorize(pre_parts[0], :bold)

        "%s %s %s %s" % [timestamp,
                         prefix,
                         pre_parts.join(" "),
                         msg ? colorize(":#{msg}", :yellow) : ""]
      end

      def format_exception(message)
        "%s %s %s" % [timestamp, colorize("!!", :red), message]
      end
    end
  end
end
