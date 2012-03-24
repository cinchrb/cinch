module Cinch
  # @note The interface of this class isn't fixed yet. You shouldn't
  #   use it yet.
  class Storage
    include Enumerable

    # @param [Hash] options
    # @param [Plugin] plugin
    def initialize(options, plugin)
    end

    # @param [Object] key
    # @return [Object, nil]
    def [](key)
    end

    # @param [Object] key
    # @param [Object] value
    # @return [value]
    def []=(key, value)
    end

    # @return [self]
    def each
      self
    end

    # @return [self]
    def each_key
      self
    end

    # @return [self]
    def each_value
      self
    end

    # @param [Object] key
    # @return [Boolean]
    def has_key?(key)
      false
    end
    alias_method :include?, :has_key?
    alias_method :key?, :has_key?
    alias_method :member?, :has_key?

    # @param [Object] key
    # @return [Object, nil] The deleted object
    def delete(key)
    end

    # @return [self]
    def delete_if
      self
    end

    def save
    end

    def unload
    end
  end
end
