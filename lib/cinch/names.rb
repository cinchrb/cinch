module Cinch
  module Names
    attr_reader :channel_names
    
    def track_names
      @channel_names = {}
    end
  end
end

class Cinch::Base
  include Cinch::Names
end
