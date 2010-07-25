dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(dir) unless $LOAD_PATH.include? dir

require 'ostruct'
require 'optparse'

require 'cinch/irc'
require 'cinch/rules'
require 'cinch/base'
require 'cinch/names'

module Cinch
  VERSION = '0.3.5'

  class << self

    # Setup bot options and return a new Cinch::Base instance
    def setup(ops={}, &blk)
      Cinch::Base.new(ops, &blk)
    end
    alias_method :configure, :setup
  end

end

