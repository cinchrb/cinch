dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(dir) unless $LOAD_PATH.include? dir

require 'cinch/irc'

module Cinch
  VERSION = '0.1'

end

