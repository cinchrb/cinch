module Cinch
  # @api private
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
  CacheManager = CachedList
end
