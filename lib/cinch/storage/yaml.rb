require "cinch/storage"
require "yaml"

module Cinch
  class Storage
    class YAML < Storage
      def initialize(options, plugin)
        # We are a basic example, so we load everything into memory. yey.
        @file = options.basedir + plugin.class.plugin_name + ".yaml"
        if File.exist?(@file)
          @yaml = ::YAML.load_file(@file) || {}
        else
          @yaml = {}
        end
        @options = options

        @mutex = Mutex.new
      end

      def [](key)
        @yaml[key]
      end

      def []=(key, value)
        @yaml[key] = value

        maybe_save
      end

      def has_key?(key)
        @yaml.has_key?(key)
      end
      alias_method :include?, :has_key?
      alias_method :key?, :has_key?
      alias_method :member?, :has_key?

      def each
        @yaml.each {|e| yield(e)}
      end

      def each_key
        @yaml.each_key {|e| yield(e)}
      end

      def each_value
        @yaml.each_value {|e| yield(e)}
      end

      def delete(key)
        @yaml.delete(key)
        maybe_save
      end

      def delete_if
        delete_keys = []
        each do |key, value|
          delete_keys << key if yield(key, value)
        end

        delete_keys.each do |key|
          delete(key)
        end
      end

      def save
        @mutex.synchronize do
          File.open(@file, "w") do |f|
            f.write @yaml.to_yaml
          end
        end
      end

      def unload
      end

      private
      def maybe_save
        save if @options.autosave
      end
    end
  end
end
