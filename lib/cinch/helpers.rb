module Cinch
  module Helpers
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
      bot.channel_manager.find_ensured(channel)
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
      bot.user_manager.find_ensured(user)
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
    #     timer(5) { puts "timer fired" }
    #   end
    #
    # @example Used as an instance method in a traditional `on` handler
    #   on :message, "start timer" do
    #     timer(5) { puts "timer fired" }
    #   end
    #
    # @param [Number] interval Interval in seconds
    # @param [Proc] block A proc to execute
    # @option options [Symbol] :method (:timer) Method to call (only if no proc is provided)
    # @option options [Boolean] :threaded (true) Call method in a thread?
    # @return [Timer]
    # @since 1.2.0
    def timer(interval, options = {}, &block)
      options = {:method => :timer, :threaded => true}.merge(options)
      block ||= self.method(options[:method])
      timer = Cinch::Timer.new(bot, interval, options[:threaded], &block)
      timer.start

      timer
    end

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
    # @since 1.2.0
    def rescue_exception
      begin
        yield
      rescue => e
        bot.logger.log_exception(e)
      end
    end
  end
end
