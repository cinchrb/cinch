module Cinch
  module Plugin
    include Helpers

    module ClassMethods
      Match = Struct.new(:pattern, :use_prefix, :method)
      Listener = Struct.new(:event, :method)
      # @api private
      Timer = Struct.new(:interval, :method, :threaded)
      Hook = Struct.new(:type, :for, :method)

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
        @__cinch_matches ||= []
        @__cinch_matches << Match.new(pattern, options[:use_prefix], options[:method])
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

      # Define a help message which will be returned on "&lt;prefix&gt;help
      # &lt;pluginname&gt;".
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
      def prefix(prefix = nil, &block)
        raise ArgumentError if prefix.nil? && block.nil?
        @__cinch_prefix = prefix || block
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

      # @example
      #   timer 5, method: :some_method
      #   def some_method
      #     Channel("#cinch-bots").send(Time.now.to_s)
      #   end
      # @param [Number] interval Interval in seconds
      # @option options [Symbol] :method (:timer) Method to call
      # @option options [Boolean] :threaded (true) Call method in a thread?
      # @return [void]
      def timer(interval, options = {})
        options = {:method => :timer, :threaded => true}.merge(options)
        @__cinch_timers ||= []
        @__cinch_timers << Timer.new(interval, options[:method], options[:threaded])
      end

      # Defines a hook which will be run before or after a handler is
      # executed, depending on the value of `type`.
      #
      # @param [Symbol<:pre, :post>] type Run the hook before or after
      #   a handler?
      # @option options [Array<:match, :listen_to, :ctcp>] :for ([:match, :listen_to, :ctcp])
      #   Which kinds of events to run the hook for.
      # @option options [Symbol] :method (true) The method to execute.
      # @return [void]
      def hook(type, options = {})
        options = {:for => [:match, :listen_to, :ctcp], :method => :hook}.merge(options)
        __hooks(type) << Hook.new(type, options[:for], options[:method])
      end

      # @return [String]
      # @api private
      def __plugin_name
        @__cinch_name || self.name.split("::").last.downcase
      end

      # @return [Hash]
      # @api private
      def __hooks(type = nil, events = nil)
        @__cinch_hooks ||= Hash.new{|h,k| h[k] = []}

        if type.nil?
          hooks = @__cinch_hooks
        else
          hooks = @__cinch_hooks[type]
        end

        if events.nil?
          return hooks
        else
          events = [*events]
          if hooks.is_a?(Hash)
            hooks = hooks.map { |k, v| v }
          end
          return hooks.select { |hook| (events & hook.for).size > 0 }
        end
      end

      # @return [void]
      # @api private
      def __register_with_bot(bot, instance)
        plugin_name = __plugin_name

        (@__cinch_listeners || []).each do |listener|
          bot.debug "[plugin] #{plugin_name}: Registering listener for type `#{listener.event}`"
          bot.on(listener.event, [], instance) do |message, plugin, *args|
            if plugin.respond_to?(listener.method)
              plugin.class.__hooks(:pre, :listen_to).each {|hook| plugin.__send__(hook.method, message)}
              plugin.__send__(listener.method, message, *args)
              plugin.class.__hooks(:post, :listen_to).each {|hook| plugin.__send__(hook.method, message)}
            end
          end
        end

        if (@__cinch_matches ||= []).empty?
          @__cinch_matches << Match.new(plugin_name, true, :execute)
        end

        prefix = @__cinch_prefix || bot.config.plugins.prefix

        @__cinch_matches.each do |pattern|
          if pattern.use_prefix
            _prefix = prefix
          elsif pattern.pattern.is_a?(String)
            _prefix = /^/
          else
            _prefix = nil
          end

          pattern_to_register = Pattern.new(_prefix, pattern.pattern)
          react_on = @__cinch_react_on || :message

          bot.debug "[plugin] #{plugin_name}: Registering executor with pattern `#{pattern_to_register.inspect}`, reacting on `#{react_on}`"

          bot.on(react_on, pattern_to_register, instance, pattern) do |message, plugin, pattern, *args|
            if plugin.respond_to?(pattern.method)
              method = plugin.method(pattern.method)
              arity = method.arity - 1
              if arity > 0
                args = args[0..arity - 1]
              elsif arity == 0
                args = []
              end
              plugin.class.__hooks(:pre, :match).each {|hook| plugin.__send__(hook.method, message)}
              method.call(message, *args)
              plugin.class.__hooks(:post, :match).each {|hook| plugin.__send__(hook.method, message)}
            end
          end
        end

        (@__cinch_ctcps || []).each do |ctcp|
          bot.debug "[plugin] #{plugin_name}: Registering CTCP `#{ctcp}`"
          bot.on(:ctcp, ctcp, instance, ctcp) do |message, plugin, ctcp, *args|
            plugin.class.__hooks(:pre, :ctcp).each {|hook| plugin.__send__(hook.method, message)}
            plugin.__send__("ctcp_#{ctcp.downcase}", message, *args)
            plugin.class.__hooks(:post, :ctcp).each {|hook| plugin.__send__(hook.method, message)}
          end
        end

        (@__cinch_timers || []).each do |timer|
          bot.debug "[plugin] #{__plugin_name}: Registering timer with interval `#{timer.interval}` for method `#{timer.method}`"
          bot.on :connect do
            Thread.new do
              loop do
                if instance.respond_to?(timer.method)
                  l = lambda {
                    begin
                      instance.__send__(timer.method)
                    rescue => e
                      bot.logger.log_exception(e)
                    end
                  }

                  if timer.threaded
                    Thread.new do
                      l.call
                    end
                  else
                    l.call
                  end
                  sleep timer.interval
                end
              end
            end
          end
        end

        if @__cinch_help_message
          bot.debug "[plugin] #{plugin_name}: Registering help message"
          bot.on(:message, "#{prefix}help #{plugin_name}", @__cinch_help_message) do |message, help_message|
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
  end
end
