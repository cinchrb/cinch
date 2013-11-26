require "cinch/cached_list"

module Cinch
  # @since 2.0.0
  # @version 1.1.0
  # @note In prior versions, this class was called UserManager
  class UserList < CachedList
    # Finds or creates a user.
    # @overload find_ensured(nick)
    #   Finds or creates a user based on his nick.
    #
    #   @param [String] nick The user's nickname
    #   @return [User]
    # @overload find_ensured(user, nick, host)
    #   Finds or creates a user based on his nick but already
    #   setting user and host.
    #
    #   @param [String] user The username
    #   @param [String] nick The nickname
    #   @param [String] host The user's hostname
    #   @return [User]
    # @return [User]
    # @see Bot#User
    def find_ensured(*args)
      user, host = nil, nil
      case args.size
      when 1
        nick = args.first
        bargs = [nick]
      when 3
        nick = args[1]
        bargs = args
        user, _, host = bargs
      else
        raise ArgumentError
      end
      downcased_nick = nick.irc_downcase(@bot.irc.isupport["CASEMAPPING"])
      @mutex.synchronize do
        user_obj = @cache[downcased_nick] ||= User.new(*bargs, @bot)
        if user && host
          # Explicitly set user and host whenever we request a User
          # object to update them on e.g. JOIN.
          user_obj.sync(:user, user, true)
          user_obj.sync(:host, host, true)
        end
        user_obj
      end
    end

    # Finds a user.
    #
    # @param [String] nick nick of a user
    # @return [User, nil]
    def find(nick)
      downcased_nick = nick.irc_downcase(@bot.irc.isupport["CASEMAPPING"])
      @mutex.synchronize do
        return @cache[downcased_nick]
      end
    end

    # @api private
    # @return [void]
    def update_nick(user)
      @mutex.synchronize do
        @cache.delete user.last_nick.irc_downcase(@bot.irc.isupport["CASEMAPPING"])
        @cache[user.nick.irc_downcase(@bot.irc.isupport["CASEMAPPING"])] = user
      end
    end

    # @api private
    # @return [void]
    def delete(user)
      @cache.delete_if {|n, u| u == user }
    end
  end
end
