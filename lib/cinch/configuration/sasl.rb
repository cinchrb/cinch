require "cinch/configuration"
require "cinch/sasl"

module Cinch
  class Configuration
    # @since 2.0.0
    class SASL < Configuration
      KnownOptions = [:username, :password, :mechanisms]

      def self.default_config
        {
          :username => nil,
          :password => nil,
          :mechanisms => [Cinch::SASL::DH_Blowfish, Cinch::SASL::Plain]
        }
      end
    end
  end
end
