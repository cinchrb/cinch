module Cinch
  class PluginManager
    include Enumerable

    def initialize(bot)
      @bot     = bot
      @plugins = []
    end

    def each
      @plugins.each { |plugin| yield(plugin)}
    end

    # @param [Class<Plugin>] plugin
    def register_plugin(plugin)
      @plugins << plugin.new(@bot)
    end

    # @param [Array<Class<Plugin>>] plugins
    def register_plugins(plugins)
      plugins.each { |plugin| register_plugin(plugin) }
    end
  end
end
