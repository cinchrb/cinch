require "cinch/configuration"

module Cinch
  # @since 1.2.0
  class SSLConfiguration < Configuration
    KnownOptions = [:use, :verify, :client_cert, :ca_path]

    def self.default_config
      {
        :use => false,
        :verify => false,
        :client_cert => nil,
        :ca_path => "/etc/ssl/certs",
      }
    end
  end
end
