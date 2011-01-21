require "cinch/cache_manager"

module Cinch
  class ChannelManager < CacheManager
    # Finds or creates a channel.
    #
    # @param [String] name name of a channel
    # @return [Channel]
    # @see Bot#Channel
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
