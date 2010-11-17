$: << File.expand_path('../../lib/', __FILE__)

require 'riot'
require "cinch"

Riot.verbose

path = File.expand_path(File.dirname __FILE__)
Dir["#{path}/cinch/**/*_test.rb"].each { |tf| require tf }
