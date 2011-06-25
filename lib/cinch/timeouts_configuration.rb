require "cinch/configuration"

module Cinch
  # @since 1.2.0
  class TimeoutsConfiguration < Configuration
    KnownOptions = [:read, :connect]

    def self.default_config
      {:read => 240, :connect => 10,}
    end
  end
end
