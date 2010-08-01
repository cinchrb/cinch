# -*- coding: utf-8 -*-
require 'socket'
require "thread"
require "ostruct"
require "newton/rubyext/module"
require "newton/rubyext/queue"
require "newton/rubyext/string"
require "newton/rubyext/infinity"

require "newton/exceptions"

require "newton/formatted_logger"
require "newton/syncable"
require "newton/message"
require "newton/message_queue"
require "newton/irc"
require "newton/channel"
require "newton/user"
require "newton/constants"
require "newton/callback"
require "newton/ban"
require "newton/mask"
require "newton/isupport"
require "newton/plugin"

Thread.abort_on_exception = true
module Newton
  VERSION = '0.1.0'

  class Bot
    # @return [Config]
    attr_accessor :config
    # @return [IRC]
    attr_accessor :irc

    # The store is used for storing state and information bot-wide,
    # mainly because the use of instance variables in bots is not
    # possible.
    #
    # @example
    #   configure do |c|
    #     …
    #     store[:message_counter] = 0
    #   end
    #
    #   on :message do
    #     store[:message_counter] += 1
    #     channel.send "This was message ##{store[:message_counter]}"
    #   end
    #
    # @return [Hash]
    attr_reader :store

    # Helper method for turning a String into a {Channel} object.
    #
    # @param [String] channel a channel name
    # @return [Channel] a {Channel} object
    # @example
    #   on :message, /^please join (#.+)$/ do |target|
    #     Channel(target).join
    #   end
    def Channel(channel)
      return channel if channel.is_a?(Channel)
      Channel.find_ensured(channel, self)
    end

    # Helper method for turning a String into an {User} object.
    #
    # @param [String] user a user's nickname
    # @return [User] an {User} object
    # @example
    #   on :message, /^tell me everything about (.+)$/ do |target|
    #     user = User(target)
    #     reply "%s is named %s and connects from %s" % [user.nick, user.name, user.host]
    #   end
    def User(user)
      return user if user.is_a?(User)
      User.find_ensured(user, self)
    end

    # @return [void]
    # @see FormattedLogger#debug
    def debug(msg)
      FormattedLogger.debug(msg)
    end

    # @return [Boolean]
    def strict?
      @config.strictness == :strict
    end

    # @yield
    def initialize(&b)
      @events = {}
      @config = OpenStruct.new({
                                 :server => "localhost",
                                 :port   => 6667,
                                 :ssl    => false,
                                 :password => nil,
                                 :nick   => "newton",
                                 :realname => "Newton",
                                 :verbose => false,
                                 :messages_per_second => 0.5,
                                 :server_queue_size => 10,
                                 :strictness => :forgiving,
                                 :message_split_start => '... ',
                                 :message_split_end   => ' ...',
                                 :plugins => OpenStruct.new({
                                                              :plugins => [],
                                                              :prefix  => "!",
                                                            }),
                               })

      @store = {}
      @semaphores = {}
      @plugins = []
      instance_eval(&b) if block_given?
    end

    # This method is used to set a bot's options. It indeed does
    # nothing else but yielding {Bot#config}, but it makes for a nice DSL.
    #
    # @yieldparam [Struct] config the bot's config
    # @return [void]
    def configure
      yield @config
    end

    # Since Newton uses threads, all handlers can be run
    # simultaneously, even the same handler multiple times. This also
    # means, that your code has to be thread-safe. Most of the time,
    # this is not a problem, but if you are accessing stored data, you
    # will most likely have to synchronize access to it. Instead of
    # managing all mutexes yourself, Newton provides a synchronize
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
    #      store[:i] = 0
    #    end
    #
    #    on :channel, /^start counting!/ do
    #      synchronize(:my_counter) do
    #        10.times do
    #          val = store[:i]
    #          # at this point, another thread might've incremented :i already.
    #          # this thread wouldn't know about it, though.
    #          store[:i] = val + 1
    #        end
    #      end
    #    end
    def synchronize(name, &block)
      semaphore = (@semaphores[name] ||= Mutex.new)
      semaphore.synchronize(&block)
    end

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
        case regexp
        when String, Integer
          if event == :ctcp
            /^#{Regexp.escape(regexp.to_s)}(?:$| .+)/
          else
            /^#{Regexp.escape(regexp.to_s)}$/
          end
        else
          regexp
        end
      end
      (@events[event] ||= []) << [regexps, args, block]
    end

    # Define helper methods in the context of the bot.
    #
    # @yield Expects a block containing method definitions
    # @return [void]
    def helpers(&b)
      Callback.class_eval(&b)
    end

    # Stop execution of the current {#on} handler.
    #
    # @return [void]
    def halt
      throw :halt
    end

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
    # @return [void]
    # @see Channel#send
    # @see User#send
    # @see #safe_msg
    def msg(recipient, text)
      text = text.to_s
      split_start = @config.message_split_start || ""
      split_end   = @config.message_split_end   || ""

      text.split(/\r\n|\r|\n/).each do |line|
        # 498 = 510 - length(":" . " PRIVMSG " . " :");
        maxlength = 498 - self.mask.to_s.length - recipient.to_s.length
        maxlength_without_end = maxlength - split_end.length

        if text.length > maxlength
          splitted = []

          while text.length > maxlength_without_end
            pos = text.rindex(/\s/, maxlength)
            r = pos || maxlength_without_end
            splitted << text.slice!(0, r) + split_end
            text = split_start + text
          end

          splitted << text
          splitted.each do |string|
            raw("PRIVMSG #{recipient} :#{string}")
          end
        else
          raw("PRIVMSG #{recipient} :#{text}")
        end
      end
    end
    alias_method :privmsg, :msg
    alias_method :send, :msg

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
      msg(recipient, Newton.filter_string(text))
    end
    alias_method :safe_privmsg, :safe_msg
    alias_method :safe_send, :safe_msg

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
      action(recipient, Newton.filter_string(text))
    end

    # Joins a list of channels.
    #
    # @param [String, Channel] channel either the name of a channel or a {Channel} object
    # @param [String] key optionally the key of the channel
    # @return [void]
    # @see Channel#join
    def join(channel, key = nil)
      Channel(channel).join(key)
    end

    # Parts a list of channels.
    #
    # @param [String, Channel] channel either the name of a channel or a {Channel} object
    # @param [String] reason an optional reason/part message
    # @return [void]
    # @see Channel#part
    def part(channel, reason = nil)
      Channel(channel).part(reason)
    end

    # @return [String]
    attr_accessor :nick
    def nick
      @config.nick
    end

    # @return [String]
    attr_reader :host
    attr_reader :mask
    attr_reader :user
    attr_reader :realname
    attr_reader :signed_on_at
    def secure?
    end

    def unknown?
      false
    end

    [:host, :mask, :user, :realname, :signed_on_at, :secure?].each do |attr|
      define_method(attr) do
        User(nick).__send__(attr)
      end
    end

    # Sets the bot's nick.
    #
    # @param [String] new_nick
    # @raise [Exceptions::NickTooLong]
    def nick=(new_nick)
      if new_nick.size > @irc.isupport["NICKLEN"] && strict?
        raise Exceptions::NickTooLong, new_nick
      end

      raw "NICK #{new_nick}"
    end

    # Disconnects from the server.
    #
    # @return [void]
    def quit(message = nil)
      command = message ? "QUIT :#{message}" : "QUIT"
      raw command
    end

    # Connects the bot to an server.
    #
    # @param [Boolean] plugins Automatically register plugins from
    #   `@config.plugins.plugins`?
    # @return [void]
    def start(plugins = true)
      register_plugins if plugins
      FormattedLogger.debug "Connecting to #{@config.server}:#{@config.port}"
      @irc = IRC.new(self, @config)
      @irc.connect
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

    # @api private
    # @return [void]
    def dispatch(event, msg = nil)
      if handlers = find(event, msg)
        handlers.each do |handler|
          regexps, args, block = *handler
          # calling Message#match multiple times is not a problem
          # because we cache the result
          if msg
            regexp = regexps.find { |rx| msg.match(rx, event) }
            captures = msg.match(regexp, event).captures
          else
            captures = []
          end

          invoke(block, args, msg, captures)
        end
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
            msg.match(regexp, type)
          }
        }
      end
    end

    def invoke(block, args, msg, match)
      # -1  splat arg, send everything
      #  0  no args, send nothing
      #  1  defined number of args, send only those
      bargs = case block.arity <=> 0
              when -1; match
              when 0; []
              when 1; match[0..block.arity-1 - args.size]
              end
      Thread.new do
        begin
          catch(:halt) do
            Callback.new(block, args, msg, self).call(*bargs)
          end
        rescue => e
          FormattedLogger.debug "#{e.backtrace.first}: #{e.message} (#{e.class})"
          e.backtrace[1..-1].each do |line|
            FormattedLogger.debug "\t" + line
          end
        end
      end
    end
  end
end
