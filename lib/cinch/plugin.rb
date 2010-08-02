module Cinch
  class Plugin
    class << self
      # Set the match pattern.
      #
      # @param [Regexp, String] pattern A pattern
      # @param [Boolean] prefix If true, the plugin prefix will
      #   automatically be prepended to the pattern.
      # @return [void]
      def match(pattern, prefix = true)
        @__newton_pattern = pattern
        @__newton_use_prefix = prefix
      end

      # Events to listen to.
      #
      # @param [String, Symbol, Integer] *types Events to listen to. Available
      #   events are all IRC commands in lowercase as symbols, all numeric
      #   replies, and the following:
      #
      #     - :channel (a channel message)
      #     - :private (a private message)
      #     - :message (both channel and private messages)
      #     - :error   (IRC errors)
      #     - :ctcp    (ctcp requests)
      # @return [void]
      def listen_to(*types)
        @__newton_listen_to = types
      end

      def ctcp(command)
        (@__newton_ctcps ||= []) << command.to_s.upcase
      end

      # Define a help message which will be returned on "<prefix>help
      # <pluginname>".
      #
      # @param [String] message
      # @return [void]
      def help(message)
        @__newton_help_message = message
      end

      # Set the plugin prefix.
      #
      # @param [String] prefix
      # @return [void]
      def prefix(prefix)
        @__newton_prefix = prefix
      end

      # Set which kind of messages to react on (i.e. call {#execute})
      #
      # @param [Symbol<:message, :channel, :private>] target React to all,
      #   only public or only private messages?
      # @return [void]
      def react_on(target)
        @__newton_react_on = target
      end

      # Define the plugin name.
      #
      # @param [String] name
      # @return [void]
      def plugin(name)
        @__newton_name = name
      end

      # @return [void]
      # @api private
      def __register_with_bot(bot, instance)
        plugin_name = @__newton_name || self.name.split("::").last.downcase

        (@__newton_listen_to || []).each do |type|
          bot.debug "[plugin] #{plugin_name}: Registering listener for type `#{type}`"
          bot.on(type, [], instance) do |message, plugin|
            plugin.listen(message) if plugin.respond_to?(:listen)
          end
        end

        pattern = @__newton_pattern || plugin_name
        prefix = @__newton_prefix || bot.config.plugins.prefix
        if (@__newton_use_prefix || @__newton_use_prefix.nil?) && prefix
          case pattern
          when Regexp
            pattern = /^#{prefix}#{pattern}/
          when String
            pattern = prefix + pattern
          end
        end

        react_on = @__newton_react_on || :message

        bot.debug "[plugin] #{plugin_name}: Registering executor with pattern `#{pattern}`, reacting on `#{react_on}`"

        bot.on(react_on, pattern, instance) do |message, plugin, *args|
          if plugin.respond_to?(:execute)
            arity = plugin.method(:execute).arity - 1
            if arity > 0
              args = args[0..arity - 1]
            elsif arity == 0
              args = []
            end
            plugin.execute(message, *args)
          end
        end

        (@__newton_ctcps || []).each do |ctcp|
          bot.debug "[plugin] #{plugin_name}: Registering CTCP `#{ctcp}`"
          bot.on(:ctcp, ctcp, instance, ctcp) do |message, plugin, ctcp, *args|
            plugin.__send__("ctcp_#{ctcp.downcase}", message, *args)
          end
        end

        if @__newton_help_message
          bot.debug "[plugin] #{plugin_name}: Registering help message"
          bot.on(:message, "#{prefix}help #{plugin_name}", @__newton_help_message) do |message, help_message|
            message.reply(help_message)
          end
        end
      end
    end

    # @return [Bot]
    attr_reader :bot
    # @return [Hash]
    attr_reader :store
    # @api private
    def initialize(bot)
      @bot = bot
      @store = bot.store[self] = {}
      self.class.__register_with_bot(bot, self)
    end

    # @param (see Bot#synchronize)
    # @yield
    # @return (see Bot#synchronize)
    # @see Bot#synchronize
    def synchronize(*args, &block)
      @bot.synchronize(*args, &block)
    end

    # This method will be executed whenever an event the plugin
    # {Plugin.listen_to listens to} occurs.
    #
    # @abstract
    # @return [void]
    # @see Plugin.listen_to
    def listen(*args)
    end

    # This method will be executed whenever a message matches the
    # {Plugin.match match pattern} of the plugin.
    #
    # @abstract
    # @return [void]
    # @see Plugin.match
    def execute(*args)
    end
  end
end
