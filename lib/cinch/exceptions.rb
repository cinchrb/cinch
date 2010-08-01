module Cinch
  module Exceptions
    # Generic error. Superclass for all Cinch-specific errors.
    class Generic < ::StandardError
    end

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

    class UnsupportedFeature < Generic
    end
  end
end
