require "cinch/configuration"
require "cinch/storage/null"

module Cinch
  # @since 2.0.0
  class StorageConfiguration < Configuration
    def self.default_config
      {
        :backend => Storage::Null
      }
    end

    def [](key)
      @table[key]
    end

    def []=(key, value)
      modifiable[new_ostruct_member(key)] = value
    end

    def load(new_config, from_default)
      _new_config = {}
      new_config.each do |option, value|
        case option
        when :backend
          _new_config[option] = Cinch::Utilities::Kernel.string_to_const(value)
        else
          _new_config[option] = value
        end
      end

      super(_new_config, from_default)
    end
  end
end
