module Cinch
  # @api private
  # @since 2.0.0
  # @version 1.1.0
  # @note In prior versions, this class was called CacheManager
  class CachedList
    include Enumerable

    def initialize(bot)
      @bot = bot
      @cache = {}
      @mutex = Mutex.new
    end

    def each(&block)
      @cache.each_value(&block)
    end
  end
end
