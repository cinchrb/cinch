lib = File.dirname(__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'socket'

require 'irc/parser'
require 'irc/message'
require 'irc/socket'

module Cinch
  # == Author
  # * Lee Jarvis - ljjarvis@gmail.com
  #
  # == Description
  # Cinch::IRC provides tools to interact with an IRC server, this
  # includes reading/writing/parsing and building a message response.
  #
  # You can use these tools through Cinch or include them directly and use
  # them on their own.
  #
  # Each class inside of this module can be used direcly as they contain
  # no references to higher level classes inside Cinch
  #
  # == Example
  #  require 'cinch/irc'
  #  require 'pp'
  #
  #  parser = Cinch::IRC::Parser.new
  #
  #  Cinch::IRC::Socket.new('irc.2600.net') do |irc|
  #    irc.nick "Cinch"
  #    irc.user "Cinch", 0, '*', "Cinch IRC bot"
  #
  #    while line = irc.read
  #      message = parser.parse(line)
  #  
  #      pp message
  #    end
  #  end
  #
  module IRC

  end
end
