# -*- coding: utf-8 -*-
require 'socket'
require "thread"
require "ostruct"
require "cinch/rubyext/module"
require "cinch/rubyext/queue"
require "cinch/rubyext/string"
require "cinch/rubyext/infinity"

require "cinch/exceptions"

require "cinch/helpers"
require "cinch/logger/logger"
require "cinch/logger/null_logger"
require "cinch/logger/formatted_logger"
require "cinch/syncable"
require "cinch/message"
require "cinch/message_queue"
require "cinch/irc"
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
require "cinch/cache_manager"
require "cinch/channel_manager"
require "cinch/user_manager"

module Cinch

  class Bot
    # @return [Config]
    attr_reader :config
    # @return [IRC]
    attr_reader :irc
    # @return [Logger]
    attr_accessor :logger
    # @return [Array<Channel>] All channels the bot currently is in
    attr_reader :channels
    # @return [String] the bot's hostname
    attr_reader :host
    # @return [Mask]
    attr_reader :mask
    # @return [String]
    attr_reader :user
    # @return [String]
    attr_reader :realname
    # @return [Time]
    attr_reader :signed_on_at
    # @return [Array<Plugin>] All registered plugins
    attr_reader :plugins
    # @return [Array<Thread>]
    # @api private
    attr_reader :handler_threads
    # @return [Boolean] whether the bot is in the process of disconnecting
    attr_reader :quitting
    # @return [UserManager]
    attr_reader :user_manager
    # @return [ChannelManager]
    attr_reader :channel_manager
    # @return [Boolean]
    # @api private
    attr_accessor :last_connection_was_successful

    # @group Helper methods

    # Helper method for turning a String into a {Channel} object.
    #
    # @param [String] channel a channel name
    # @return [Channel] a {Channel} object
    # @example
    #   on :message, /^please join (#.+)$/ do |m, target|
    #     Channel(target).join
    #   end
    def Channel(channel)
      return channel if channel.is_a?(Channel)
      @channel_manager.find_ensured(channel)
    end

    # Helper method for turning a String into an {User} object.
    #
    # @param [String] user a user's nickname
    # @return [User] an {User} object
    # @example
    #   on :message, /^tell me everything about (.+)$/ do |m, target|
    #     user = User(target)
    #     m.reply "%s is named %s and connects from %s" % [user.nick, user.name, user.host]
    #   end
    def User(user)
      return user if user.is_a?(User)
      @user_manager.find_ensured(user)
    end

    # Define helper methods in the context of the bot.
    #
    # @yield Expects a block containing method definitions
    # @return [void]
    def helpers(&b)
      Callback.class_eval(&b)
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

    # Stop execution of the current {#on} handler.
    #
    # @return [void]
    def halt
      throw :halt
    end

    # @endgroup
    # @group Sending messages

    # Sends a raw message to the server.
    #
    # @param [String] command The message to send.
    # @return [void]
    # @see IRC#message
    def raw(command)
      @irc.message(command)
    end

    # Sends a PRIVMSG to a recipient (a channel or user).
    # You should be using {Channel#send} and {User#send} instead.
    #
    # @param [String] recipient the recipient
    # @param [String] text the message to send
    # @param [Boolean] notice Use NOTICE instead of PRIVMSG?
    # @return [void]
    # @see Channel#send
    # @see User#send
    # @see #safe_msg
    def msg(recipient, text, notice = false)
      text = text.to_s
      split_start = @config.message_split_start || ""
      split_end   = @config.message_split_end   || ""
      command = notice ? "NOTICE" : "PRIVMSG"

      text.split(/\r\n|\r|\n/).each do |line|
        maxlength = 510 - (":" + " #{command} " + " :").size
        maxlength = maxlength - self.mask.to_s.length - recipient.to_s.length
        maxlength_without_end = maxlength - split_end.bytesize

        if line.bytesize > maxlength
          splitted = []

          while line.bytesize > maxlength_without_end
            pos = line.rindex(/\s/, maxlength_without_end)
            r = pos || maxlength_without_end
            splitted << line.slice!(0, r) + split_end.tr(" ", "\u00A0")
            line = split_start.tr(" ", "\u00A0") + line.lstrip
          end

          splitted << line
          splitted[0, (@config.max_messages || splitted.size)].each do |string|
            string.tr!("\u00A0", " ") # clean string from any non-breaking spaces
            raw("#{command} #{recipient} :#{string}")
          end
        else
          raw("#{command} #{recipient} :#{line}")
        end
      end
    end
    alias_method :privmsg, :msg
    alias_method :send, :msg

    # Sends a NOTICE to a recipient (a channel or user).
    # You should be using {Channel#notice} and {User#notice} instead.
    #
    # @param [String] recipient the recipient
    # @param [String] text the message to send
    # @return [void]
    # @see Channel#notice
    # @see User#notice
    # @see #safe_notice
    def notice(recipient, text)
      msg(recipient, text, true)
    end

    # Like {#msg}, but remove any non-printable characters from
    # `text`. The purpose of this method is to send text of untrusted
    # sources, like other users or feeds.
    #
    # Note: this will **break** any mIRC color codes embedded in the
    # string.
    #
    # @return (see #msg)
    # @param (see #msg)
    # @see #msg
    # @see User#safe_send
    # @see Channel#safe_send
    # @todo Handle mIRC color codes more gracefully.
    def safe_msg(recipient, text)
      msg(recipient, Cinch.filter_string(text))
    end
    alias_method :safe_privmsg, :safe_msg
    alias_method :safe_send, :safe_msg

    # Like {#safe_msg} but for notices.
    #
    # @return (see #safe_msg)
    # @param (see #safe_msg)
    # @see #safe_notice
    # @see #notice
    # @see User#safe_notice
    # @see Channel#safe_notice
    # @todo (see #safe_msg)
    def safe_notice(recipient, text)
      msg(recipient, Cinch.filter_string(text), true)
    end

    # Invoke an action (/me) in/to a recipient (a channel or user).
    # You should be using {Channel#action} and {User#action} instead.
    #
    # @param [String] recipient the recipient
    # @param [String] text the message to send
    # @return [void]
    # @see Channel#action
    # @see User#action
    # @see #safe_action
    def action(recipient, text)
      raw("PRIVMSG #{recipient} :\001ACTION #{text}\001")
    end

    # Like {#action}, but remove any non-printable characters from
    # `text`. The purpose of this method is to send text from
    # untrusted sources, like other users or feeds.
    #
    # Note: this will **break** any mIRC color codes embedded in the
    # string.
    #
    # @param (see #action)
    # @return (see #action)
    # @see #action
    # @see Channel#safe_action
    # @see User#safe_action
    # @todo Handle mIRC color codes more gracefully.
    def safe_action(recipient, text)
      action(recipient, Cinch.filter_string(text))
    end

    # @endgroup
    # @group Events &amp; Plugins

    # Registers a handler.
    #
    # @param [String, Symbol, Integer] event the event to match. Available
    #   events are all IRC commands in lowercase as symbols, all numeric
    #   replies, and the following:
    #
    #     - :channel (a channel message)
    #     - :private (a private message)
    #     - :message (both channel and private messages)
    #     - :error   (handling errors, use a numeric error code as `match`)
    #     - :ctcp    (ctcp requests, use a ctcp command as `match`)
    #
    # @param [Regexp, String, Integer] match every message of the
    #   right event will be checked against this argument and the event
    #   will only be called if it matches
    #
    # @yieldparam [String] *args each capture group of the regex will
    #   be one argument to the block. It is optional to accept them,
    #   though
    #
    # @return [void]
    def on(event, regexps = [], *args, &block)
      regexps = [*regexps]
      regexps = [//] if regexps.empty?

      event = event.to_sym

      regexps.map! do |regexp|
        pattern = case regexp
                 when Pattern
                   regexp
                 when Regexp
                   Pattern.new(nil, regexp, nil)
                 else
                   if event == :ctcp
                     Pattern.new(/^/, /#{Regexp.escape(regexp.to_s)}(?:$| .+)/, nil)
                   else
                     Pattern.new(/^/, /#{Regexp.escape(regexp.to_s)}/, /$/)
                   end
                 end
        debug "[on handler] Registering handler with pattern `#{pattern.inspect}`, reacting on `#{event}`"
        pattern
      end
      (@events[event] ||= []) << [regexps, args, block]
    end

    # @param [Symbol] event The event type
    # @param [Message, nil] msg The message which is responsible for
    #   and attached to the event, or nil.
    # @param [Array] *arguments A list of additional arguments to pass
    #   to event handlers
    # @return [void]
    def dispatch(event, msg = nil, *arguments)
      if handlers = find(event, msg)
        handlers.each do |handler|
          regexps, args, block = *handler
          # calling Message#match multiple times is not a problem
          # because we cache the result
          if msg
            regexp = regexps.find { |rx|
              msg.match(rx.to_r(msg), event)
            }
            captures = msg.match(regexp.to_r(msg), event).captures
          else
            captures = []
          end

          invoke(block, args, msg, captures, arguments)
        end
      end
    end

    # Register all plugins from `@config.plugins.plugins`.
    #
    # @return [void]
    def register_plugins
      @config.plugins.plugins.each do |plugin|
        register_plugin(plugin)
      end
    end

    # Registers a plugin.
    #
    # @param [Class<Plugin>] plugin The plugin class to register
    # @return [void]
    def register_plugin(plugin)
      @plugins << plugin.new(self)
    end

    # @endgroup
    # @group Bot Control

    # This method is used to set a bot's options. It indeed does
    # nothing else but yielding {Bot#config}, but it makes for a nice DSL.
    #
    # @yieldparam [Struct] config the bot's config
    # @return [void]
    def configure(&block)
      @callback.instance_exec(@config, &block)
    end

    # Disconnects from the server.
    #
    # @param [String] message The quit message to send while quitting
    # @return [void]
    def quit(message = nil)
      @quitting = true
      command = message ? "QUIT :#{message}" : "QUIT"
      raw command
    end

    # Connects the bot to a server.
    #
    # @param [Boolean] plugins Automatically register plugins from
    #   `@config.plugins.plugins`?
    # @return [void]
    # Connects the bot to a server.
    #
    # @param [Boolean] plugins Automatically register plugins from
    #   `@config.plugins.plugins`?
    # @return [void]
    def start(plugins = true)
      @reconnects = 0
      register_plugins if plugins

      begin
        @user_manager.each do |user|
          user.in_whois = false
          user.unsync_all
        end # reset state of all users

        @channel_manager.each do |channel|
          channel.unsync_all
        end # reset state of all channels

        @logger.debug "Connecting to #{@config.server}:#{@config.port}"
        @irc = IRC.new(self)
        @irc.connect

        if @config.reconnect && !@quitting
          # double the delay for each unsuccesful reconnection attempt
          if @last_connection_was_successful
            @reconnects = 0
            @last_connection_was_successful = false
          else
            @reconnects += 1
          end

          # Sleep for a few seconds before reconnecting to prevent being
          # throttled by the IRC server
          wait = 2**@reconnects
          @logger.debug "Waiting #{wait} seconds before reconnecting"
          sleep wait
        end
      end while @config.reconnect and not @quitting
    end

    # @endgroup
    # @group Channel Control

    # Join a channel.
    #
    # @param [String, Channel] channel either the name of a channel or a {Channel} object
    # @param [String] key optionally the key of the channel
    # @return [void]
    # @see Channel#join
    def join(channel, key = nil)
      Channel(channel).join(key)
    end

    # Part a channel.
    #
    # @param [String, Channel] channel either the name of a channel or a {Channel} object
    # @param [String] reason an optional reason/part message
    # @return [void]
    # @see Channel#part
    def part(channel, reason = nil)
      Channel(channel).part(reason)
    end

    # @endgroup

    # (see Logger::Logger#debug)
    # @see Logger::Logger#debug
    def debug(msg)
      @logger.debug(msg)
    end

    # @return [Boolean] True if the bot reports ISUPPORT violations as
    #   exceptions.
    def strict?
      @config.strictness == :strict
    end

    # @yield
    def initialize(&b)
      @logger = Logger::FormattedLogger.new($stderr)
      @events = {}
      @config = OpenStruct.new({
                                 :server => "localhost",
                                 :port   => 6667,
                                 :ssl    => OpenStruct.new({
                                                             :use => false,
                                                             :verify => false,
                                                             :client_cert => nil,
                                                             :ca_path => "/etc/ssl/certs",
                                                           }),
                                 :password => nil,
                                 :nick   => "cinch",
                                 :nicks  => nil,
                                 :realname => "cinch",
                                 :user => "cinch",
                                 :verbose => true,
                                 :messages_per_second => 0.5,
                                 :server_queue_size => 10,
                                 :strictness => :forgiving,
                                 :message_split_start => '... ',
                                 :message_split_end   => ' ...',
                                 :max_messages => nil,
                                 :plugins => OpenStruct.new({
                                                              :plugins => [],
                                                              :prefix  => /^!/,
                                                              :suffix  => nil,
                                                              :options => Hash.new {|h,k| h[k] = {}},
                                                            }),
                                 :channels => [],
                                 :encoding => :irc,
                                 :reconnect => true,
                                 :local_host => nil,
                                 :timeouts => OpenStruct.new({
                                                               :read => 240,
                                                               :connect => 10,
                                                             }),
                                 :ping_interval => 120,
                               })

      @semaphores_mutex = Mutex.new
      @semaphores = Hash.new { |h,k| h[k] = Mutex.new }
      @plugins = []
      @callback = Callback.new(self)
      @channels = []
      @handler_threads = []
      @quitting = false

      @user_manager = UserManager.new(self)
      @channel_manager = ChannelManager.new(self)

      instance_eval(&b) if block_given?

      on :connect do
        bot.config.channels.each do |channel|
          bot.join channel
        end
      end
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
    attr_accessor :nick
    undef_method "nick"
    undef_method "nick="
    def nick
      @config.nick
    end

    def nick=(new_nick)
      if new_nick.size > @irc.isupport["NICKLEN"] && strict?
        raise Exceptions::NickTooLong, new_nick
      end
      @config.nick = new_nick
      raw "NICK #{new_nick}"
    end

    # Try to create a free nick, first by cycling through all
    # available alternatives and then by appending underscores.
    #
    # @param [String] base The base nick to start trying from
    # @api private
    # @return String
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

    # @return [Boolean] True if the bot is using SSL to connect to the
    #   server.
    def secure?
      @config[:ssl] == true || (@config[:ssl].is_a?(Hash) && @config[:ssl][:use])
    end

    # This method is only provided in order to give Bot and User a
    # common interface.
    #
    # @return [false] Always returns `false`.
    # @see User#unknown? See User#unknown? for the method's real use.
    def unknown?
      false
    end

    [:host, :mask, :user, :realname, :signed_on_at, :secure?].each do |attr|
      define_method(attr) do
        User(nick).__send__(attr)
      end
    end

    private
    def find(type, msg = nil)
      if events = @events[type]
        if msg.nil?
          return events
        end

        events.select { |regexps|
          regexps.first.any? { |regexp|
            msg.match(regexp.to_r(msg), type)
          }
        }
      end
    end

    def invoke(block, args, msg, match, arguments)
      bargs = match + arguments
      @handler_threads << Thread.new do
        begin
          catch(:halt) do
            @callback.instance_exec(msg, *args, *bargs, &block)
          end
        rescue => e
          @logger.log_exception(e)
        ensure
          @handler_threads.delete Thread.current
        end
      end
    end
  end
end
