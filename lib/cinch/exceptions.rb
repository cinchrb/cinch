module Cinch
  # A collection of exceptions.
  module Exceptions
    # Generic error. Superclass for all Cinch-specific errors.
    class Generic < ::StandardError
    end

    # Generic error when an argument is too long.
    class ArgumentTooLong < Generic
    end

    # Error that is raised when a topic is too long to be set.
    class TopicTooLong < ArgumentTooLong
    end

    # Error that is raised when a nick is too long to be used.
    class NickTooLong < ArgumentTooLong
    end

    # Error that is raised when a kick reason is too long.
    class KickReasonTooLong < ArgumentTooLong
    end

    # Raised whenever Cinch discovers a feature it doesn't support
    # yet.
    class UnsupportedFeature < Generic
    end

    # Raised when Cinch discovers a user or channel mode, which it
    # doesn't support yet.
    class UnsupportedMode < Generic
      def initialize(mode)
        super "Cinch does not support the mode '#{mode}' yet."
      end
    end

    # Error stating that an invalid mode string was encountered.
    class InvalidModeString < Generic
    end

    # Raised when a synced attribute hasn't been available for too
    # long.
    class SyncedAttributeNotAvailable < Generic
    end
  end
end
