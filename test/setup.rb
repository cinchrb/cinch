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

path = File.expand_path(File.dirname __FILE__)
Dir["#{path}/cinch/**/*_test.rb"].each { |tf| require tf }
