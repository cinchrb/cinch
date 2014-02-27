# -*- coding: utf-8 -*-
require 'socket'
require "thread"
require "ostruct"
require "cinch/rubyext/module"
require "cinch/rubyext/string"
require "cinch/rubyext/float"

require "cinch/exceptions"

require "cinch/handler"
require "cinch/helpers"

require "cinch/logger_list"
require "cinch/logger"

require "cinch/logger/formatted_logger"
require "cinch/syncable"
require "cinch/message"
require "cinch/message_queue"
require "cinch/irc"
require "cinch/target"
require "cinch/channel"
require "cinch/user"
require "cinch/constants"
require "cinch/callback"
require "cinch/ban"
require "cinch/mask"
require "cinch/isupport"
require "cinch/plugin"
require "cinch/pattern"
require "cinch/mode_parser"
require "cinch/dcc"
require "cinch/sasl"

require "cinch/handler_list"
require "cinch/cached_list"
require "cinch/channel_list"
require "cinch/user_list"
require "cinch/plugin_list"

require "cinch/timer"
require "cinch/formatting"

require "cinch/configuration"
require "cinch/configuration/bot"
require "cinch/configuration/plugins"
require "cinch/configuration/ssl"
require "cinch/configuration/timeouts"
require "cinch/configuration/dcc"
require "cinch/configuration/sasl"

module Cinch
  # @attr nick
  # @version 2.0.0
  class Bot < User
    include Helpers


    # @return [Configuration::Bot]
    # @version 2.0.0
    attr_reader :config

    # The underlying IRC connection
    #
    # @return [IRC]
    attr_reader :irc

    # The logger list containing all loggers
    #
    # @return [LoggerList]
    # @since 2.0.0
    attr_accessor :loggers

    # @return [Array<Channel>] All channels the bot currently is in
    attr_reader :channels

    # @return [PluginList] The {PluginList} giving access to
    #   (un)loading plugins
    # @version 2.0.0
    attr_reader :plugins

    # @return [Boolean] whether the bot is in the process of disconnecting
    attr_reader :quitting

    # @return [UserList] All {User users} the bot knows about.
    # @see UserList
    # @since 1.1.0
    attr_reader :user_list

    # @return [ChannelList] All {Channel channels} the bot knows about.
    # @see ChannelList
    # @since 1.1.0
    attr_reader :channel_list

    # @return [Boolean]
    # @api private
    attr_accessor :last_connection_was_successful

    # @return [Callback]
    # @api private
    attr_reader :callback

    # The {HandlerList}, providing access to all registered plugins
    # and plugin manipulation as well as {HandlerList#dispatch calling handlers}.
    #
    # @return [HandlerList]
    # @see HandlerList
    # @since 2.0.0
    attr_reader :handlers

    # The bot's modes.
    #
    # @return [Array<String>]
    # @since 2.0.0
    attr_reader :modes

    # @group Helper methods

    # Define helper methods in the context of the bot.
    #
    # @yield Expects a block containing method definitions
    # @return [void]
    def helpers(&b)
      @callback.instance_eval(&b)
    end

    # Since Cinch uses threads, all handlers can be run
    # simultaneously, even the same handler multiple times. This also
    # means, that your code has to be thread-safe. Most of the time,
    # this is not a problem, but if you are accessing stored data, you
    # will most likely have to synchronize access to it. Instead of
    # managing all mutexes yourself, Cinch provides a synchronize
    # method, which takes a name and block.
    #
    # Synchronize blocks with the same name share the same mutex,
    # which means that only one of them will be executed at a time.
    #
    # @param [String, Symbol] name a name for the synchronize block.
    # @return [void]
    # @yield
    #
    # @example
    #    configure do |c|
    #      …
    #      @i = 0
    #    end
    #
    #    on :channel, /^start counting!/ do
    #      synchronize(:my_counter) do
    #        10.times do
    #          val = @i
    #          # at this point, another thread might've incremented :i already.
    #          # this thread wouldn't know about it, though.
    #          @i = val + 1
    #        end
    #      end
    #    end
    def synchronize(name, &block)
      # Must run the default block +/ fetch in a thread safe way in order to
      # ensure we always get the same mutex for a given name.
      semaphore = @semaphores_mutex.synchronize { @semaphores[name] }
      semaphore.synchronize(&block)
    end

    # @endgroup

    # @group Events &amp; Plugins

    # Registers a handler.
    #
    # @param [String, Symbol, Integer] event the event to match. For a
    #   list of available events, check the {file:docs/events.md Events
    #   documentation}.
    #
    # @param [Regexp, Pattern, String] regexp every message of the
    #   right event will be checked against this argument and the event
    #   will only be called if it matches
    #
    # @param [Array<Object>] args Arguments that should be passed to
    #   the block, additionally to capture groups of the regexp.
    #
    # @yieldparam [Array<String>] args each capture group of the regex will
    #   be one argument to the block.
    #
    # @return [Handler] The handlers that have been registered
    def on(event, regexp = //, *args, &block)
      event = event.to_s.to_sym

      pattern = case regexp
                when Pattern
                  regexp
                when Regexp
                  Pattern.new(nil, regexp, nil)
                else
                  if event == :ctcp
                    Pattern.generate(:ctcp, regexp)
                  else
                    Pattern.new(/^/, /#{Regexp.escape(regexp.to_s)}/, /$/)
                  end
                end

      handler = Handler.new(self, event, pattern, {args: args, execute_in_callback: true}, &block)
      @handlers.register(handler)

      return handler
    end

    # @endgroup
    # @group Bot Control

    # This method is used to set a bot's options. It indeed does
    # nothing else but yielding {Bot#config}, but it makes for a nice DSL.
    #
    # @yieldparam [Struct] config the bot's config
    # @return [void]
    def configure
      yield @config
    end

    # Disconnects from the server.
    #
    # @param [String] message The quit message to send while quitting
    # @return [void]
    def quit(message = nil)
      @quitting = true
      command   = message ? "QUIT :#{message}" : "QUIT"

      @irc.send command
    end

    # Connects the bot to a server.
    #
    # @param [Boolean] plugins Automatically register plugins from
    #   `@config.plugins.plugins`?
    # @return [void]
    def start(plugins = true)
      @reconnects = 0
      @plugins.register_plugins(@config.plugins.plugins) if plugins

      begin
        @user_list.each do |user|
          user.in_whois = false
          user.unsync_all
        end # reset state of all users

        @channel_list.each do |channel|
          channel.unsync_all
        end # reset state of all channels

        @channels = [] # reset list of channels the bot is in

        @join_handler.unregister if @join_handler
        @join_timer.stop if @join_timer

        join_lambda = lambda { @config.channels.each { |channel| Channel(channel).join }}

        if @config.delay_joins.is_a?(Symbol)
          @join_handler = join_handler = on(@config.delay_joins) {
            join_handler.unregister
            join_lambda.call
          }
        else
          @join_timer = Timer.new(self, interval: @config.delay_joins, shots: 1) {
            join_lambda.call
          }
        end

        @modes = []

        @loggers.info "Connecting to #{@config.server}:#{@config.port}"
        @irc = IRC.new(self)
        @irc.start

        if @config.reconnect && !@quitting
          # double the delay for each unsuccesful reconnection attempt
          if @last_connection_was_successful
            @reconnects = 0
            @last_connection_was_successful = false
          else
            @reconnects += 1
          end

          # Throttle reconnect attempts
          wait = 2**@reconnects
          wait = @config.max_reconnect_delay if wait > @config.max_reconnect_delay
          @loggers.info "Waiting #{wait} seconds before reconnecting"
          start_time = Time.now
          while !@quitting && (Time.now - start_time) < wait
            sleep 1
          end
        end
      end while @config.reconnect and not @quitting
    end

    # @endgroup
    # @group Channel Control

    # Join a channel.
    #
    # @param [String, Channel] channel either the name of a channel or a {Channel} object
    # @param [String] key optionally the key of the channel
    # @return [Channel] The joined channel
    # @see Channel#join
    def join(channel, key = nil)
      channel = Channel(channel)
      channel.join(key)

      channel
    end

    # Part a channel.
    #
    # @param [String, Channel] channel either the name of a channel or a {Channel} object
    # @param [String] reason an optional reason/part message
    # @return [Channel] The channel that was left
    # @see Channel#part
    def part(channel, reason = nil)
      channel = Channel(channel)
      channel.part(reason)

      channel
    end

    # @endgroup

    # @return [Boolean] True if the bot reports ISUPPORT violations as
    #   exceptions.
    def strict?
      @config.strictness == :strict
    end

    # @yield
    def initialize(&b)
      @loggers = LoggerList.new
      @loggers << Logger::FormattedLogger.new($stderr)

      @config           = Configuration::Bot.new
      @handlers         = HandlerList.new
      @semaphores_mutex = Mutex.new
      @semaphores       = Hash.new { |h, k| h[k] = Mutex.new }
      @callback         = Callback.new(self)
      @channels         = []
      @quitting         = false
      @modes            = []

      @user_list    = UserList.new(self)
      @channel_list = ChannelList.new(self)
      @plugins      = PluginList.new(self)

      @join_handler = nil
      @join_timer   = nil

      super(nil, self)
      instance_eval(&b) if block_given?
    end

    # @since 2.0.0
    # @return [self]
    # @api private
    def bot
      # This method is needed for the Helpers interface
      self
    end

    # Sets a mode on the bot.
    #
    # @param [String] mode
    # @return [void]
    # @since 2.0.0
    # @see Bot#modes
    # @see Bot#unset_mode
    def set_mode(mode)
      @modes << mode unless @modes.include?(mode)
      @irc.send "MODE #{nick} +#{mode}"
    end

    # Unsets a mode on the bot.
    #
    # @param [String] mode
    # @return [void]
    # @since 2.0.0
    def unset_mode(mode)
      @modes.delete(mode)
      @irc.send "MODE #{nick} -#{mode}"
    end

    # @since 2.0.0
    def modes=(modes)
      (@modes - modes).each do |mode|
        unset_mode(mode)
      end

      (modes - @modes).each do |mode|
        set_mode(mode)
      end
    end

    # Used for updating the bot's nick from within the IRC parser.
    #
    # @param [String] nick
    # @api private
    # @return [String]
    def set_nick(nick)
      @name = nick
    end

    # The bot's nickname.
    # @overload nick=(new_nick)
    #   @raise [Exceptions::NickTooLong] Raised if the bot is
    #     operating in {#strict? strict mode} and the new nickname is
    #     too long
    #   @return [String]
    # @overload nick
    #   @return [String]
    # @return [String]
    def nick
      @name
    end

    def nick=(new_nick)
      if new_nick.size > @irc.isupport["NICKLEN"] && strict?
        raise Exceptions::NickTooLong, new_nick
      end
      @config.nick = new_nick
      @irc.send "NICK #{new_nick}"
    end

    # Gain oper privileges.
    #
    # @param [String] password
    # @param [String] user The username to use. Defaults to the bot's
    #   nickname
    # @since 2.1.0
    # @return [void]
    def oper(password, user = nil)
      user ||= self.nick
      @irc.send "OPER #{user} #{password}"
    end

    # Try to create a free nick, first by cycling through all
    # available alternatives and then by appending underscores.
    #
    # @param [String] base The base nick to start trying from
    # @api private
    # @return [String]
    # @since 2.0.0
    def generate_next_nick!(base = nil)
      nicks = @config.nicks || []

      if base
        # if `base` is not in our list of nicks to try, assume that it's
        # custom and just append an underscore
        if !nicks.include?(base)
          new_nick =  base + "_"
        else
          # if we have a base, try the next nick or append an
          # underscore if no more nicks are left
          new_index = nicks.index(base) + 1
          if nicks[new_index]
            new_nick = nicks[new_index]
          else
            new_nick = base + "_"
          end
        end
      else
        # if we have no base, try the first possible nick
        new_nick = @config.nicks ? @config.nicks.first : @config.nick
      end

      @config.nick = new_nick
    end

    # @return [String]
    def inspect
      "#<Bot nick=#{@name.inspect}>"
    end
  end
end
