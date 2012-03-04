module Cinch
  # This is the base logger class from which all loggers have to
  # inherit.
  #
  # @version 2.0.0
  class Logger
    # @private
    LevelOrder = [:debug, :log, :info, :warn, :error, :fatal]

    # @return [Array<:debug, :log, :info, :warn, :error, :fatal>]
    #   The minimum level of events to log
    attr_accessor :level

    # @return [Mutex]
    # @api private
    attr_reader :mutex

    # @return [IO]
    # @api private
    attr_reader :output

    # @param [IO] output The I/O object to write log data to
    def initialize(output)
      @output = output
      @mutex  = Mutex.new
      @level  = :debug
    end

    # Logs a debugging message.
    #
    # @param [String] message
    # @return [void]
    # @version 2.0.0
    def debug(message)
      log(message, :debug)
    end

    # Logs an error message.
    #
    # @param [String] message
    # @return [void]
    # @since 2.0.0
    def error(message)
      log(message, :error)
    end

    # Logs a fatal message.
    #
    # @param [String] message
    # @return [void]
    # @since 2.0.0
    def fatal(message)
      log(message, :fatal)
    end

    # Logs an info message.
    #
    # @param [String] message
    # @return [void]
    # @since 2.0.0
    def info(message)
      log(message, :info)
    end

    # Logs a warning message.
    #
    # @param [String] message
    # @return [void]
    # @since 2.0.0
    def warn(message)
      log(message, :warn)
    end

    # Logs an incoming IRC message.
    #
    # @param [String] message
    # @return [void]
    # @since 2.0.0
    def incoming(message)
      log(message, :incoming, :log)
    end

    # Logs an outgoing IRC message.
    #
    # @param [String] message
    # @return [void]
    # @since 2.0.0
    def outgoing(message)
      log(message, :outgoing, :log)
    end

    # Logs an exception.
    #
    # @param [Exception] e
    # @return [void]
    # @since 2.0.0
    def exception(e)
      log(e.message, :exception, :error)
    end

    # Logs a message.
    #
    # @param [String, Array] messages The message(s) to log
    # @param [:debug, :incoming, :outgoing, :info, :warn,
    #   :exception, :error, :fatal] event The kind of event that
    #   triggered the message
    # @param [:debug, :info, :warn, :error, :fatal] level The level of the message
    # @return [void]
    # @version 2.0.0
    def log(messages, event = :debug, level = event)
      return unless will_log?(level)
      @mutex.synchronize do
        Array(messages).each do |message|
          message = format_general(message)
          message = format_message(message, event)

          next if message.nil?
          @output.puts message.encode("locale", {:invalid => :replace, :undef => :replace})
        end
      end
    end

    # @param [:debug, :info, :warn, :error, :fatal] level
    # @return [Boolean] Whether the currently set logging level will
    #   allow the passed in level to be logged
    # @since 2.0.0
    def will_log?(level)
      LevelOrder.index(level) >= LevelOrder.index(@level)
    end

    private
    def format_message(message, level)
      __send__ "format_#{level}", message
    end

    def format_general(message)
      message
    end

    def format_debug(message)
      message
    end

    def format_error(message)
      message
    end

    def format_info(message)
      message
    end

    def format_warn(message)
      message
    end

    def format_incoming(message)
      message
    end

    def format_outgoing(message)
      message
    end

    def format_exception(message)
      message
    end
  end
end
