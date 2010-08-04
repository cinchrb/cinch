module Cinch
  module Plugin
    module ClassMethods
      Pattern = Struct.new(:pattern, :use_prefix, :method)
      # Set a match pattern.
      #
      # @param [Regexp, String] pattern A pattern
      # @option options [Symbol] :method (:execute) The method to execute
      # @option options [Boolean] :use_prefix (true) If true, the
      #   plugin prefix will automatically be prepended to the
      #   pattern.
      # @return [void]
      def match(pattern, options = {})
        options = {:use_prefix => true, :method => :execute}.merge(options)
        @__newton_patterns ||= []
        @__newton_patterns << Pattern.new(pattern, options[:use_prefix], options[:method])
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

        if @__newton_patterns.empty?
          @__newton_patterns << Pattern.new(plugin_name, true, nil)
        end

        @__newton_patterns.each do |pattern|
          prefix = @__newton_prefix || bot.config.plugins.prefix
          if pattern.use_prefix && prefix
            case pattern.pattern
            when Regexp
              pattern.pattern = /^#{prefix}#{pattern.pattern}/
            when String
              pattern.pattern = prefix + pattern.pattern
            end
          end

          react_on = @__newton_react_on || :message

          bot.debug "[plugin] #{plugin_name}: Registering executor with pattern `#{pattern.pattern}`, reacting on `#{react_on}`"

          bot.on(react_on, pattern.pattern, instance, pattern) do |message, plugin, pattern, *args|
            if plugin.respond_to?(pattern.method)
              method = plugin.method(pattern.method)
              arity = method.arity - 1
              if arity > 0
                args = args[0..arity - 1]
              elsif arity == 0
                args = []
              end
              method.call(message, *args)
            end
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
    # @api private
    def initialize(bot)
      @bot = bot
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

    def self.included(by)
      p by
      by.extend ClassMethods
    end
  end
end
