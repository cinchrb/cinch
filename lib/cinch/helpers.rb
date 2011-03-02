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
  end
end
