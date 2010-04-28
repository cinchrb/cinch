dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(dir) unless $LOAD_PATH.include? dir

require 'ostruct'
require 'optparse'

require 'cinch/irc'
require 'cinch/rules'
require 'cinch/base'

module Cinch
  VERSION = '0.2.6'

  # Setup bot options and return a new Cinch::Base instance
  def self.setup(ops={}, &blk)
    Cinch::Base.new(ops, &blk)
  end

end

