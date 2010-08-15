module Cinch
  module Logger
    # @abstract
    class Logger
      def initialize(output)
        raise
      end

      def debug(message)
        raise
      end

      def log(message, kind = :generic)
        raise
      end

      def log_exception(e)
        raise
      end
    end
  end
end
