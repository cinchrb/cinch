begin
  # rr requires ObjectSpace
  require "java"
  JRuby.objectspace = true
rescue LoadError
end

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
  end
rescue LoadError
end

$: << File.expand_path('../../lib/', __FILE__)

require 'riot'
require 'riot/rr'
require "cinch"

Riot.verbose
class Riot::Situation
  def test_user(mask = "cinchy!cinch@cinchrb.org")
    mock(test_user = Cinch::User.new("cinchy", nil)).mask { Cinch::Mask.new(mask) }
    test_user
  end
end


class TestBot < Cinch::Bot
  attr_reader :raw_log
  def initialize(*args)
    super
    @irc = TestIRC.new
    @raw_log = []
  end

  def raw(command)
    @raw_log << command
  end
end

class TestIRC
  attr_reader :isupport
  def initialize
    @isupport = Cinch::ISupport.new
  end
end

class Cinch::Message
  attr_reader :bot
end

Bot = TestBot.new

path = File.expand_path(File.dirname __FILE__)
Dir["#{path}/cinch/**/*_test.rb"].each { |tf| require tf }
