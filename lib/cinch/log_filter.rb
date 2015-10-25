module Cinch
  # LogFilter describes an interface for filtering log messages before
  # they're printed.
  #
  # @abstract
  # @since 2.3.0
  class LogFilter
    # filter is called for each log message, except for exceptions. It
    # returns a new string, which is the one that should be printed, or
    # further filtered by other filters. Returning nil will drop the
    # message.
    #
    # @param [String] message The message that is to be logged
    # @param [:debug, :incoming, :outgoing, :info, :warn, :exception,
    #   :error, :fatal] event The kind of message
    # @return [String, nil] The modified message, as it should be
    #   logged, or nil if the message shouldn't be logged at all
    def filter(message, event)
    end
  end
end
