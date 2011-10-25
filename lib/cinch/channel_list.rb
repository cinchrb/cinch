require "cinch/cached_list"

module Cinch
  # @since 2.0.0
  # @version 1.1.0
  # @note In prior versions, this class was called ChannelManager
  class ChannelList < CachedList
    # Finds or creates a channel.
    #
    # @param [String] name name of a channel
    # @return [Channel]
    # @see Helpers#Channel
    def find_ensured(name)
      downcased_name = name.irc_downcase(@bot.irc.isupport["CASEMAPPING"])
      @mutex.synchronize do
        @cache[downcased_name] ||= Channel.new(name, @bot)
      end
    end

    # Finds a channel.
    #
    # @param [String] name name of a channel
    # @return [Channel, nil]
    def find(name)
      downcased_name = name.irc_downcase(@bot.irc.isupport["CASEMAPPING"])
      @cache[downcased_name]
    end
  end
end
