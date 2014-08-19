require 'cinch'

class Nickchange
  include Cinch::Plugin
  listen_to :nick

  def listen(m)
    # This will send a PM to the user who changed their nick and inform
    # them of their old nick.
    m.reply "Your old nick was: #{m.user.last_nick}" ,true
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "cinch_nickchange"
    c.server          = "irc.freenode.org"
    c.channels        = ["#cinch-bots"]
    c.verbose         = true
    c.plugins.plugins = [Nickchange]
  end
end

bot.start
