require 'cinch'

class SomeCommand
  include Cinch::Plugin

  set :prefix, /^~/
  match "somecommand"

  def execute(m)
    m.reply "Successful"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.org"
    c.channels = ["#cinch-bots"]
    c.plugins.plugins = [SomeCommand]
  end
end

bot.start

