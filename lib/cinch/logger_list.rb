module Cinch
  # This class allows Cinch to use multiple loggers at once. A common
  # use-case would be to log formatted messages to STDERR and a
  # pisg-compatible log to a file.
  #
  # It inherits directly from Array, so adding new loggers is as easy
  # as calling LoggerList#push.
  #
  # @attr_writer level
  # @since 2.0.0
  class LoggerList < Array
    # A list of log filters that will be applied before emitting a log
    # message.
    #
    # @return [Array<LogFilter>]
    # @since 2.3.0
    attr_accessor :filters
    def initialize(*args)
      @filters = []
      super
    end

    # (see Logger#level=)
    def level=(level)
      each {|l| l.level = level}
    end

    # (see Logger#log)
    def log(messages, event = :debug, level = event)
      do_log(messages, event, level)
    end

    # (see Logger#debug)
    def debug(message)
      do_log(message, :debug)
    end

    # (see Logger#error)
    def error(message)
      do_log(message, :error)
    end

    # (see Logger#error)
    def fatal(message)
      do_log(message, :fatal)
    end

    # (see Logger#info)
    def info(message)
      do_log(message, :info)
    end

    # (see Logger#warn)
    def warn(message)
      do_log(message, :warn)
    end

    # (see Logger#incoming)
    def incoming(message)
      do_log(message, :incoming, :log)
    end

    # (see Logger#outgoing)
    def outgoing(message)
      do_log(message, :outgoing, :log)
    end

    # (see Logger#exception)
    def exception(e)
      do_log(e, :exception, :error)
    end

    private
    def do_log(messages, event, level = event)
      messages = Array(messages)
      if event != :exception
        messages.map! { |m|
          @filters.each do |f|
            m = f.filter(m, event)
            if m.nil?
              break
            end
          end
          m
        }.compact
      end
      each {|l| l.log(messages, event, level)}
    end
  end
end
