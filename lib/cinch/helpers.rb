# -*- coding: utf-8 -*-
module Cinch
  # The Helpers module contains a number of methods whose purpose is
  # to make writing plugins easier by hiding parts of the API. The
  # {#Channel} helper, for example, provides an easier way for turning
  # a String object into a {Channel} object than directly using
  # {ChannelList}: Compare `Channel("#some_channel")` with
  # `bot.channel_list.find_ensured("#some_channel")`.
  #
  # The Helpers module automatically gets included in all plugins.
  module Helpers
    # @group Type casts

    # Helper method for turning a String into a {Target} object.
    #
    # @param [String] target a target name
    # @return [Target] a {Target} object
    # @example
    #   on :message, /^message (.+)$/ do |m, target|
    #     Target(target).send "hi!"
    #   end
    # @since 2.0.0
    def Target(target)
      return target if target.is_a?(Target)
      Target.new(target, bot)
    end

    # Helper method for turning a String into a {Channel} object.
    #
    # @param [String] channel a channel name
    # @return [Channel] a {Channel} object
    # @example
    #   on :message, /^please join (#.+)$/ do |m, target|
    #     Channel(target).join
    #   end
    # @since 1.0.0
    def Channel(channel)
      return channel if channel.is_a?(Channel)
      bot.channel_list.find_ensured(channel)
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
    # @since 1.0.0
    def User(user)
      return user if user.is_a?(User)
      if user == bot.nick
        bot
      else
        bot.user_list.find_ensured(user)
      end
    end

    # @example Used as a class method in a plugin
    #   timer 5, method: :some_method
    #   def some_method
    #     Channel("#cinch-bots").send(Time.now.to_s)
    #   end
    #
    # @example Used as an instance method in a plugin
    #   match "start timer"
    #   def execute(m)
    #     Timer(5) { puts "timer fired" }
    #   end
    #
    # @example Used as an instance method in a traditional `on` handler
    #   on :message, "start timer" do
    #     Timer(5) { puts "timer fired" }
    #   end
    #
    # @param [Numeric] interval Interval in seconds
    # @param [Proc] block A proc to execute
    # @option options [Symbol] :method (:timer) Method to call (only
    #   if no proc is provided)
    # @option options [Boolean] :threaded (true) Call method in a
    #   thread?
    # @option options [Integer] :shots (Float::INFINITY) How often
    #   should the timer fire?
    # @option options [Boolean] :start_automatically (true) If true,
    #   the timer will automatically start after the bot finished
    #   connecting.
    # @option options [Boolean] :stop_automaticall (true) If true, the
    #   timer will automatically stop when the bot disconnects.
    # @return [Timer]
    # @since 2.0.0
    def Timer(interval, options = {}, &block)
      options = {:method => :timer, :threaded => true, :interval => interval}.merge(options)
      block ||= self.method(options[:method])
      timer   = Cinch::Timer.new(bot, options, &block)
      timer.start

      if self.respond_to?(:timers)
        timers << timer
      end

      timer
    end

    # @endgroup

    # @group Logging

    # Use this method to automatically log exceptions to the loggers.
    #
    # @example
    #   def my_method
    #     rescue_exception do
    #       something_that_might_raise()
    #     end
    #   end
    #
    # @return [void]
    # @since 2.0.0
    def rescue_exception
      begin
        yield
      rescue => e
        bot.loggers.exception(e)
      end
    end

    # (see Logger#log)
    def log(messages, event = :debug, level = event)
      if self.is_a?(Cinch::Plugin)
        messages = Array(messages).map {|m|
          "[#{self.class}] " + m
        }
      end
      @bot.loggers.log(messages, event, level)
    end

    # (see Logger#debug)
    def debug(message)
      log(message, :debug)
    end

    # (see Logger#error)
    def error(message)
      log(message, :error)
    end

    # (see Logger#fatal)
    def fatal(message)
      log(message, :fatal)
    end

    # (see Logger#info)
    def info(message)
      log(message, :info)
    end

    # (see Logger#warn)
    def warn(message)
      log(message, :warn)
    end

    # (see Logger#incoming)
    def incoming(message)
      log(message, :incoming, :log)
    end

    # (see Logger#outgoing)
    def outgoing(message)
      log(message, :outgoing, :log)
    end

    # (see Logger#exception)
    def exception(e)
      log(e.message, :exception, :error)
    end
    # @endgroup

    # @group Formatting

    # (see Formatting.format)
    def Format(*settings, string)
      Formatting.format(*settings, string)
    end
    alias_method :Color, :Format # deprecated
    undef_method(:Color) # yardoc hack

    def Color(*args)
      Cinch::Utilities::Deprecation.print_deprecation("2.2.0", "Helpers.Color", "Helpers.Format")
      Format(*args)
    end

    # (see .sanitize)
    def Sanitize(string)
      Cinch::Helpers.sanitize(string)
    end

    # Deletes all characters in the ranges 0–8, 10–31 as well as the
    # character 127, that is all non-printable characters and
    # newlines.
    #
    # This method is useful for filtering text from external sources
    # before sending it to IRC.
    #
    # Note that this method does not gracefully handle mIRC color
    # codes, because it will leave the numeric arguments behind. If
    # your text comes from IRC, you may want to filter it through
    # {#Unformat} first. If you want to send sanitized input that
    # includes your own formatting, first use this method, then add
    # your formatting.
    #
    # There exist methods for sending messages that automatically
    # call this method, namely {Target#safe_msg},
    # {Target#safe_notice}, and {Target#safe_action}.
    #
    # @param [String] string The string to filter
    # @return [String] The filtered string
    # @since 2.2.0
    def self.sanitize(string)
      string.gsub(/[\x00-\x08\x10-\x1f\x7f]/, '')
    end

    # (see Formatting.unformat)
    def Unformat(string)
      Formatting.unformat(string)
    end

    # @endgroup
  end
end
