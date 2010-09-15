module Cinch
  module Plugin
    include Helpers

    module ClassMethods
      Pattern = Struct.new(:pattern, :use_prefix, :to_me, :method)
      Listener = Struct.new(:event, :method)

      # Set a match pattern.
      #
      # @param [Regexp, String] pattern A pattern
      # @option options [Symbol] :method (:execute) The method to execute
      # @option options [Boolean] :use_prefix (true) If true, the
      #   plugin prefix will automatically be prepended to the
      #   pattern.
      # @option options [Boolean] :to_me (false) If true, the
      #   method will only be triggered if the message is addressed
      #   to the bot.
      # @return [void]
      def match(pattern, options = {})
        options = {:use_prefix => true, :to_me => false, :method => :execute}.merge(options)
        @__cinch_patterns ||= []
        @__cinch_patterns << Pattern.new(pattern, options[:use_prefix], options[:to_me], options[:method])
      end

      # Events to listen to.
      # @overload listen_to(*types, options = {})
      #   @param [String, Symbol, Integer] *types Events to listen to. Available
      #     events are all IRC commands in lowercase as symbols, all numeric
      #     replies, and the following:
      #
      #       - :channel (a channel message)
      #       - :private (a private message)
      #       - :message (both channel and private messages)
      #       - :error   (IRC errors)
      #       - :ctcp    (ctcp requests)
      #
      #   @param [Hash] options
      #   @option options [Symbol] :method (:listen) The method to
      #     execute
      #   @return [void]
      def listen_to(*types)
        options = {:method => :listen}
        if types.last.is_a?(Hash)
          options.merge!(types.pop)
        end

        @__cinch_listeners ||= []

        types.each do |type|
          @__cinch_listeners << Listener.new(type, options[:method])
        end
      end

      def ctcp(command)
        (@__cinch_ctcps ||= []) << command.to_s.upcase
      end

      # Define a help message which will be returned on "<prefix>help
      # <pluginname>".
      #
      # @param [String] message
      # @return [void]
      def help(message)
        @__cinch_help_message = message
      end

      # Set the plugin prefix.
      #
      # @param [String] prefix
      # @return [void]
      def prefix(prefix)
        @__cinch_prefix = prefix
      end

      # Set which kind of messages to react on (i.e. call {#execute})
      #
      # @param [Symbol<:message, :channel, :private>] target React to all,
      #   only public or only private messages?
      # @return [void]
      def react_on(target)
        @__cinch_react_on = target
      end

      # Define the plugin name.
      #
      # @param [String] name
      # @return [void]
      def plugin(name)
        @__cinch_name = name
      end

      # @return [String]
      # @api private
      def __plugin_name
        @__cinch_name || self.name.split("::").last.downcase
      end

      # @return [void]
      # @api private
      def __register_with_bot(bot, instance)
        plugin_name = __plugin_name

        (@__cinch_listeners || []).each do |listener|
          bot.debug "[plugin] #{plugin_name}: Registering listener for type `#{listener.event}`"
          bot.on(listener.event, [], instance) do |message, plugin|
            if plugin.responds_in?(message.channel) && plugin.respond_to?(listener.method)
              plugin.__send__(listener.method, message)
            end
          end
        end

        if (@__cinch_patterns ||= []).empty?
          @__cinch_patterns << Pattern.new(plugin_name, true, false, nil)
        end

        prefix = @__cinch_prefix || bot.config.plugins.prefix
        if prefix.is_a?(String)
          prefix = Regexp.escape(prefix)
        end
        @__cinch_patterns.each do |pattern|
          pattern_to_register = nil

          if pattern.use_prefix && prefix
            case pattern.pattern
            when Regexp
              pattern_to_register = /^#{prefix}#{pattern.pattern}/
            when String
              pattern_to_register = prefix + pattern.pattern
            end
          else
            pattern_to_register = pattern.pattern
          end

          react_on = @__cinch_react_on || :message
          bot.debug "[plugin] #{plugin_name}: Registering executor with pattern `#{pattern_to_register}`, reacting on `#{react_on}`"

          bot.on(react_on, pattern_to_register, instance, pattern) do |message, plugin, pattern, *args|
            if plugin.responds_in?(message.channel) && plugin.respond_to?(pattern.method)
              method = plugin.method(pattern.method)
              arity = method.arity - 1
              if arity > 0
                args = args[0..arity - 1]
              elsif arity == 0
                args = []
              end
              # if the message is not to a channel, then it has to be directed to us.
              # otherwise, the message have to include our name in it somewhere
              if pattern.to_me && (!message.channel? || message.message.match(plugin.bot.nick))
                method.call(message, *args)
              elsif !pattern.to_me
                method.call(message, *args)
              end
            end
          end
        end

        (@__cinch_ctcps || []).each do |ctcp|
          bot.debug "[plugin] #{plugin_name}: Registering CTCP `#{ctcp}`"
          bot.on(:ctcp, ctcp, instance, ctcp) do |message, plugin, ctcp, *args|
            plugin.__send__("ctcp_#{ctcp.downcase}", message, *args)
          end
        end

        if @__cinch_help_message
          bot.debug "[plugin] #{plugin_name}: Registering help message"
          bot.on(:message, /#{prefix}help #{Regexp.escape(plugin_name)}/, @__cinch_help_message) do |message, help_message|
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
      @__cinch_channels = []
      self.class.__register_with_bot(bot, self)
    end

    # (see Bot#synchronize)
    def synchronize(*args, &block)
      @bot.synchronize(*args, &block)
    end

    # This method will be executed whenever an event the plugin
    # {Plugin::ClassMethods#listen_to listens to} occurs.
    #
    # @abstract
    # @return [void]
    # @see Plugin::ClassMethods#listen_to
    def listen(*args)
    end

    # This method will be executed whenever a message matches the
    # {Plugin::ClassMethods#match match pattern} of the plugin.
    #
    # @abstract
    # @return [void]
    # @see Plugin::ClassMethods#match
    def execute(*args)
    end

    # Provides access to plugin-specific options.
    #
    # @return [Hash] A hash of options
    def config
      @bot.config.plugins.options[self.class]
    end

    def self.included(by)
      by.extend ClassMethods
    end

    # Sets the channels this plugin will listen to
    #
    # @param [Array<String>] channels Will only react to events in these channels
    # @return [void]
    def responds_in(chans)
      @__cinch_channels = [chans].flatten
    end

    # Checks if this plugin is set to respond to a given channel
    #
    # @param [Channel] channel
    # @return [Boolean]
    # @api private
    def responds_in?(channel)
      @__cinch_channels.empty? || @__cinch_channels.include?(channel.name)
    end
  end
end