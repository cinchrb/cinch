module Cinch
  class Storage
    include Enumerable

    def initialize(options, plugin)
    end

    def [](key)
    end

    def []=(key, value)
    end

    def each
    end

    def each_key
    end

    def each_value
    end

    def has_key?(key)
    end
    alias_method :include?, :has_key?
    alias_method :key?, :has_key?
    alias_method :member?, :has_key?

    def delete(key)
    end

    def delete_if
    end

    def save
    end

    def unload
    end
  end
end
