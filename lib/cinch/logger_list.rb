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
    # (see Logger#level=)
    def level=(level)
      each {|l| l.level = level}
    end

    # (see Logger#log)
    def log(messages, event = :debug, level = event)
      each {|l| l.log(messages, event, level)}
    end

    # (see Logger#debug)
    def debug(message)
      each {|l| l.debug(message)}
    end

    # (see Logger#error)
    def error(message)
      each {|l| l.error(message)}
    end

    # (see Logger#error)
    def fatal(message)
      each {|l| l.fatal(message)}
    end

    # (see Logger#info)
    def info(message)
      each {|l| l.info(message)}
    end

    # (see Logger#warn)
    def warn(message)
      each {|l| l.warn(message)}
    end

    # (see Logger#incoming)
    def incoming(message)
      each {|l| l.incoming(message)}
    end

    # (see Logger#outgoing)
    def outgoing(message)
      each {|l| l.outgoing(message)}
    end

    # (see Logger#exception)
    def exception(e)
      each {|l| l.exception(e)}
    end
  end
end
