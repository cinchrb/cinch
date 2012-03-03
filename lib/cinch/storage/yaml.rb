require "cinch/storage"
require "yaml"

module Cinch
  class Storage
    # A basic storage backed by YAML, using one file per plugin.
    class YAML < Storage
      # (see Storage#initialize)
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

      # (see Storage#[])
      def [](key)
        @yaml[key]
      end

      # (see Strage#[]=)
      def []=(key, value)
        @yaml[key] = value
      end

      # (see Storage#has_key?)
      def has_key?(key)
        @yaml.has_key?(key)
      end
      alias_method :include?, :has_key?
      alias_method :key?, :has_key?
      alias_method :member?, :has_key?

      # (see Storage#each)
      def each
        @yaml.each {|e| yield(e)}

        self
      end

      # (see Storage#each_key)
      def each_key
        @yaml.each_key {|e| yield(e)}

        self
      end

      # (see Storage#each_value)
      def each_value
        @yaml.each_value {|e| yield(e)}

        self
      end

      # (see Storage#delete)
      def delete(key)
        obj = @yaml.delete(key)

        obj
      end

      # (see Storage#delete_if)
      def delete_if
        delete_keys = []
        each do |key, value|
          delete_keys << key if yield(key, value)
        end

        delete_keys.each do |key|
          delete(key)
        end

        self
      end

      # (see Storage#save)
      def save
        @mutex.synchronize do
          File.open(@file, "w") do |f|
            f.write @yaml.to_yaml
          end
        end
      end

      # (see Storage#unload)
      def unload
      end
    end
  end
end
