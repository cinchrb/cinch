module Cinch
  module Plugin
    include Helpers

    # @since 1.2.0
    module ClassAttributes
      # @since 1.2.0
      attr_accessor :hooks

      # @since 1.2.0
      attr_writer   :react_on

      # @since 1.2.0
      attr_writer   :plugin_name

      # @since 1.2.0
      attr_reader   :matchers

      # @since 1.2.0
      attr_reader   :listeners

      # @since 1.2.0
      attr_reader   :timers

      # @since 1.2.0
      attr_reader   :ctcps

      # @since 1.2.0
      attr_writer   :help

      # @since 1.2.0
      attr_writer   :prefix

      # @since 1.2.0
      attr_writer   :suffix
    end

    module ClassMethods
      # @api private
      Match = Struct.new(:pattern, :use_prefix, :use_suffix, :method)
      # @api private
      Listener = Struct.new(:event, :method)
      # @api private
      Timer = Struct.new(:interval, :method, :threaded, :registered)
      # @api private
      Hook = Struct.new(:type, :for, :method)

      # @api private
      def self.extended(by)
        by.extend ClassAttributes
      end


      # Set a match pattern.
      #
      # @param [Regexp, String] pattern A pattern
      # @option options [Symbol] :method (:execute) The method to execute
      # @option options [Boolean] :use_prefix (true) If true, the
      #   plugin prefix will automatically be prepended to the
      #   pattern.
      # @option options [Boolean] :use_suffix (true) If true, the
      #   plugin suffix will automatically be appended to the
      #   pattern.
      # @return [void]
      def match(pattern, options = {})
        options = {:use_prefix => true, :use_suffix => true, :method => :execute}.merge(options)
        @matchers ||= []
        @matchers << Match.new(pattern, options[:use_prefix], options[:use_suffix], options[:method])
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

        @listeners ||= []

        types.each do |type|
          @listeners << Listener.new(type, options[:method])
        end
      end

      def ctcp(command)
        (@ctcps ||= []) << command.to_s.upcase
      end

      # Set or query the help message.
      # @overload help()
      #   @return [String, nil] The help message
      #   @since 1.2.0
      #
      # @overload help(message)
      #   Sets the help message
      #
      #   @param [String] message
      #   @return [void]
      #   @deprecated See {#set} or {ClassAttributes#help=} instead
      # @return [String, nil, void]
      def help(*args)
        case args.size
        when 0
          return @help
        when 1
          self.help = args.first
        else
          raise ArgumentError # TODO proper error message
        end
      end

      # Set or query the plugin prefix.
      # @overload prefix()
      #   @return [String, Regexp, Proc] The plugin prefix
      #   @since 1.2.0
      #
      # @overload prefix(prefix = nil, &block)
      #   Sets the plugin prefix
      #
      #   @param [String, Regexp, Proc] prefix
      #   @return [void]
      #   @deprecated See {#set} or {ClassAttributes#prefix=} instead
      # @return [String, Regexp, Proc, void]
      def prefix(prefix = nil, &block)
        return @prefix if prefix.nil? && block.nil?
        self.prefix = prefix || block
      end

      # Set or query the plugin suffix.
      # @overload suffix()
      #   @return [String, Regexp, Proc] The plugin suffix
      #   @since 1.2.0
      #
      # @overload suffix(suffix = nil, &block)
      #   Sets the plugin suffix
      #
      #   @param [String, Regexp, Proc] suffix
      #   @return [void]
      #   @deprecated See {#set} or {ClassAttributes#suffix=} instead
      # @return [String, Regexp, Proc, void]
      def suffix(suffix = nil, &block)
        return @suffix if suffix.nil? && block.nil?
        self.suffix = suffix || block
      end

      # Set or query which kind of messages to react on (i.e. call {#execute})
      # @overload react_on()
      #   @return [Array<Symbol<:message, :channel, :private>>] What kind of messages to react on
      #   @since 1.2.0
      # @overload react_on(events)
      #   Set which kind of messages to react on
      #   @param [Array<Symbol<:message, :channel, :private>>] events Which events to react on
      #   @return [void]
      #   @deprecated See {#set} or {ClassAttributes#react_on=} instead
      # @return [Array<Symbol>, void]
      def react_on(*args)
        case args.size
        when 0
          return @react_on
        when 1
          self.react_on = args.first
        else
          raise ArgumentError # TODO proper error message
        end
      end

      # Set or query the plugin name.
      # @overload plugin_name()
      #   @return [String] The plugin name
      #   @since 1.2.0
      #
      # @overload plugin_name(name)
      #   Sets the plugin name
      #
      #   @param [String] name
      #   @return [void]
      #   @deprecated See {#set} or {ClassAttributes#plugin_name=} instead
      # @return [String, void]
      def plugin_name(*args)
        case args.size
        when 0
          return @plugin_name || self.name.split("::").last.downcase
        when 1
          self.plugin_name = args.first
        else
          raise ArgumentError # TODO proper error message
        end
      end
      alias_method :plugin, :plugin_name

      # @example
      #   timer 5, method: :some_method
      #   def some_method
      #     Channel("#cinch-bots").send(Time.now.to_s)
      #   end
      #
      # @param [Number] interval Interval in seconds
      # @param [Proc] block A proc to execute
      # @option options [Symbol] :method (:timer) Method to call (only if no proc is provided)
      # @option options [Boolean] :threaded (true) Call method in a thread?
      # @return [void]
      def timer(interval, options = {}, &block)
        options = {:method => :timer, :threaded => true}.merge(options)
        @timers ||= []
        @timers << Timer.new(interval, block || options[:method], options[:threaded], false)
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

      # @return [Hash]
      # @api private
      def __hooks(type = nil, events = nil)
        @hooks ||= Hash.new{|h,k| h[k] = []}

        if type.nil?
          hooks = @hooks
        else
          hooks = @hooks[type]
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
        (@listeners || []).each do |listener|
          bot.debug "[plugin] #{plugin_name}: Registering listener for type `#{listener.event}`"
          bot.on(listener.event, [], instance) do |message, plugin, *args|
            if plugin.respond_to?(listener.method)
              plugin.class.__hooks(:pre, :listen_to).each {|hook| plugin.__send__(hook.method, message)}
              plugin.__send__(listener.method, message, *args)
              plugin.class.__hooks(:post, :listen_to).each {|hook| plugin.__send__(hook.method, message)}
            end
          end
        end

        if (@matchers ||= []).empty?
          @matchers << Match.new(plugin_name, true, true, :execute)
        end

        prefix = @prefix || bot.config.plugins.prefix
        suffix = @suffix || bot.config.plugins.suffix

        @matchers.each do |pattern|
          _prefix = pattern.use_prefix ? prefix : nil
          _suffix = pattern.use_suffix ? suffix : nil

          pattern_to_register = Pattern.new(_prefix, pattern.pattern, _suffix)
          react_on = @react_on || :message

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

        (@ctcps || []).each do |ctcp|
          bot.debug "[plugin] #{plugin_name}: Registering CTCP `#{ctcp}`"
          bot.on(:ctcp, ctcp, instance, ctcp) do |message, plugin, ctcp, *args|
            plugin.class.__hooks(:pre, :ctcp).each {|hook| plugin.__send__(hook.method, message)}
            plugin.__send__("ctcp_#{ctcp.downcase}", message, *args)
            plugin.class.__hooks(:post, :ctcp).each {|hook| plugin.__send__(hook.method, message)}
          end
        end

        (@timers || []).each do |timer|
          # TODO move debug message to instance method
          bot.debug "[plugin] #{plugin_name}: Registering timer with interval `#{timer.interval}` for method `#{timer.method}`"
          bot.on :connect do
            next if timer.registered
            instance.timer(timer.interval,
                           {:method => timer.method, :threaded => timer.threaded})
            timer.registered = true
          end
        end

        if @help_message
          bot.debug "[plugin] #{plugin_name}: Registering help message"
          help_pattern = Pattern.new(prefix, "help #{plugin_name}", suffix)
          bot.on(:message, help_pattern, @__cinch_help_message) do |message, help_message|
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
      @bot.config.plugins.options[self.class] || {}
    end

    # @api private
    def self.included(by)
      by.extend ClassMethods
    end
  end
end
