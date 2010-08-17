module Cinch
  module Logger
    # This is an abstract class describing the logger interface. All
    # loggers should inherit from this class and provide all necessary
    # methods.
    #
    # Note: You cannot initialize this class directly.
    #
    # @abstract
    class Logger
      def initialize(output)
        raise
      end

      # This method can be used by plugins to log custom messages.
      #
      # @param [String] message The message to log
      # @return [void]
      def debug(message)
        raise
      end

      # This method is used by {#debug} and {#log_exception} to log
      # messages, and also by the IRC parser to log incoming and
      # outgoing messages. You should not have to call this.
      #
      # @param [String] message The message to log
      # @param [Symbol<:debug, :generic, :incoming, :outgoing>] kind
      #   The kind of message to log
      # @return [void]
      def log(message, kind = :generic)
        raise
      end

      # This method is used for logging messages.
      #
      # @param [Exception] e The exception to log
      # @return [void]
      def log_exception(e)
        raise
      end
    end
  end
end
