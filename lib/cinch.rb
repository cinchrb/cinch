dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(dir) unless $LOAD_PATH.include? dir

require 'ostruct'

require 'cinch/irc'
require 'cinch/base'

module Cinch
  VERSION = '0.1'

  # Setup a bot
  def self.setup(ops={}, &blk)
    Cinch::Base.new(ops, &blk)
  end

end

