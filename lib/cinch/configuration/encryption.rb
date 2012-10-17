require "cinch/configuration"

module Cinch
  class Configuration
    class Encryption < Configuration
      KnownOptions = [:targets]

      # (see Configuration.default_config)
      def self.default_config
        {
          :targets => {},
        }
      end
    end
  end
end
