require 'cinch'

class TimedPlugin
  include Cinch::Plugin

  timer 5, method: :timed
  def timed
    Channel("#cinch-bots").send "5 seconds have passed"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "cinch_timer"
    c.server          = "irc.freenode.org"
    c.channels        = ["#cinch-bots"]
    c.verbose         = true
    c.plugins.plugins = [TimedPlugin]
  end
end

bot.start
