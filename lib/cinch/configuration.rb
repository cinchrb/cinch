module Cinch
  # @since 2.0.0
  class Configuration < OpenStruct
    KnownOptions = []

    # Generate a default configuration.
    #
    # @return [Hash]
    def self.default_config
      {}
    end

    def initialize(base = nil)
      base ||= self.class.default_config
      super(base)
    end

    # @return [Hash]
    def to_h
      @table.clone
    end

    def [](key)
      # FIXME also adjust method_missing
      raise ArgumentError, "Unknown option #{key}" unless self.class::KnownOptions.include?(key)
      @table[key]
    end

    def []=(key, value)
      # FIXME also adjust method_missing
      raise ArgumentError, "Unknown option #{key}" unless self.class::KnownOptions.include?(key)
      modifiable[new_ostruct_member(key)] = value
    end

    # Loads a configuration from a hash by merging the hash with
    # either the current configuration or the default configuration.
    #
    # @param [Hash] new_config The configuration to load
    # @param [Boolean] from_default If true, the configuration won't
    #   be merged with the currently set up configuration (by prior
    #   calls to {#load} or {Bot#configure}) but with the default
    #   configuration.
    # @return [void]
    def load(new_config, from_default = false)
      if from_default
        @table = self.class.default_config
      end

      new_config.each do |option, value|
        if value.is_a?(Hash)
          if self[option].is_a?(Configuration)
            self[option].load(value)
          else
            # recursive merging is handled by subclasses like
            # Configuration::Plugins
            self[option] = value
          end
        else
          self[option] = value
        end
      end
    end

    # Like {#load} but always uses the default configuration
    #
    # @param [Hash] new_config (see #load_config)
    # @return [void]
    # @see #load
    def load!(new_config)
      load(new_config, true)
    end
  end
end
