require "cinch/configuration"

module Cinch
  class Configuration
    # @since 2.0.0
    class SASL < Configuration
      KnownOptions = [:username, :password]

      def self.default_config
        {
          :username => nil,
          :password => nil,
        }
      end
    end
  end
end
