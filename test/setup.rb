begin
  # rr requires ObjectSpace
  require "java"
  JRuby.objectspace = true
rescue LoadError
end

if ENV["SIMPLECOV"]
  begin
    require 'simplecov'
    SimpleCov.start do
      add_filter "/test/"
    end
  rescue LoadError
  end
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

require "cinch/logger/null_logger"
Bot = TestBot.new
Bot.logger = Cinch::Logger::NullLogger.new


require "thread"
class FakeSocket
  def initialize
    @queue = Queue.new
  end

  def __write(s)
    @queue << s
  end

  def __wait_until_empty
    loop do
      return if @queue.empty?
      sleep 0.001
    end
  end

  def readline
    @queue.pop
  end
end

class FakeMessageQueue
  attr_reader :messages
  def initialize
    @messages = []
  end

  def queue(s)
    @messages << s
  end
end

Thread.abort_on_exception = true

path = File.expand_path(File.dirname __FILE__)
Dir["#{path}/cinch/**/*_test.rb"].each { |tf| require tf }
