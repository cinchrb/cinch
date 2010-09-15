require 'cinch'

class RespondsInMessenger
  include Cinch::Plugin

  match /msg (.+?) (.+)/
  def initialize(*args)
    super
    responds_in "#cinch-bots"
  end
  def execute(m, receiver, message)
    User(receiver).send(message)
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick   = "CinchBot"
    c.channels = ["#cinch-bots", "#cinch"]
    c.plugins.plugins = [RespondsInMessenger]
  end
end

bot.start