module Cinch
  # @since 1.2.0
  class PluginList < Array
    def initialize(bot)
      @bot     = bot
      super()
    end

    # @param [Class<Plugin>] plugin
    def register_plugin(plugin)
      self << plugin.new(@bot)
    end

    # @param [Array<Class<Plugin>>] plugins
    def register_plugins(plugins)
      plugins.each { |plugin| register_plugin(plugin) }
    end
  end
end
