require "cinch/configuration"

module Cinch
  class TimeoutsConfiguration < Configuration
    KnownOptions = [:read, :connect]

    def self.default_config
      {:read => 240, :connect => 10,}
    end
  end
end
