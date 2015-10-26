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
      messages = Array(messages).map {|m| filter(m, event)}.compact
      each {|l| l.log(messages, event, level)}
    end

    # (see Logger#debug)
    def debug(message)
      (m = filter(message, :debug)) && each {|l| l.debug(m)}
    end

    # (see Logger#error)
    def error(message)
      (m = filter(message, :error)) && each {|l| l.error(m)}
    end

    # (see Logger#error)
    def fatal(message)
      (m = filter(message, :fatal)) && each {|l| l.fatal(m)}
    end

    # (see Logger#info)
    def info(message)
      (m = filter(message, :info)) && each {|l| l.info(m)}
    end

    # (see Logger#warn)
    def warn(message)
      (m = filter(message, :warn)) && each {|l| l.warn(m)}
    end

    # (see Logger#incoming)
    def incoming(message)
      (m = filter(message, :incoming)) && each {|l| l.incoming(m)}
    end

    # (see Logger#outgoing)
    def outgoing(message)
      (m = filter(message, :outgoing)) && each {|l| l.outgoing(m)}
    end

    # (see Logger#exception)
    def exception(e)
      each {|l| l.exception(e)}
    end

    private
    def filter(m, ev)
      @filters.each do |f|
        m = f.filter(m, ev)
        if m.nil?
          break
        end
      end
      m
    end
  end
end
