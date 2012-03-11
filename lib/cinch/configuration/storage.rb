require "cinch/configuration"
require "cinch/storage/null"

module Cinch
  class Configuration
    # @since 2.0.0
    class Storage < Configuration
      KnownOptions = [:backend]

      def self.default_config
        {
          :backend => Cinch::Storage::Null
        }
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
end
