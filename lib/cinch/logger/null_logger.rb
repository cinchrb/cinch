require "cinch/logger/logger"
module Cinch
  module Logger
    class NullLogger < Cinch::Logger::Logger
      def initialize(*args)
        $stderr.puts "Deprecation warning: Beginning with version 1.2.0, the NullLogger shouldn't be used anymore"
      end

      def log(*args)
      end
    end
  end
end
