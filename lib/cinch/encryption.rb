require "openssl"

module Cinch
  module Encryption
    def self.get_mechanism(name)
      self.const_get(name.to_s.capitalize)
    end
  end
end

