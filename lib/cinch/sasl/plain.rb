require "base64"
require "cinch/sasl/mechanism"

module Cinch
  module SASL
    # The simplest mechanisms simply transmits the username and
    # password without adding any encryption or hashing. As such it's more
    # insecure than DH-BLOWFISH and should only be used in combination with
    # SSL.
    class Plain < Mechanism
      class << self
        # @return [String]
        def mechanism_name
          "PLAIN"
        end

        # @param [String] user
        # @param [String] password
        # @return [String]
        def generate(user, password, _ = nil)
          Base64.strict_encode64([user, user, password].join("\0"))
        end
      end
    end
  end
end
