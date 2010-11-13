require 'riot'
require File.expand_path('../../lib/cinch', __FILE__)

Riot.verbose

path = File.expand_path(File.dirname __FILE__)
Dir["#{path}/cinch/**/*_test.rb"].each { |tf| require tf }