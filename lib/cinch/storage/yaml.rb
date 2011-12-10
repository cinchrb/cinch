require "cinch/storage"

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

        save if @options.autosave
      end

      def each
        @yaml.each {|e| yield(e)}
      end

      def each_key
        @yaml.each_key {|e| yield(e)}
      end

      def each_value
        @yaml.each_value {|e| yield(e)}
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
    end
  end
end
