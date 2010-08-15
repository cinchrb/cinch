module Cinch
  module Logger
    class NullLogger
      def initialize(output = nil)
      end

      def debug(message)
      end

      def log(message, kind = :generic)
      end

      def log_exception(e)
      end
    end
  end
end
