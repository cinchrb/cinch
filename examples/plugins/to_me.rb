require 'cinch'

class PrivateMessenger
  include Cinch::Plugin

  # example trigger: "CinchBot: msg injekt YEEEEAH!"
  #              or: "msg injekt YEEEEEAH!" in a private message to the bot
  match /msg (.+?) (.+)/, :to_me => true, :use_prefix => false
  def execute(m, receiver, message)
    User(receiver).send(message)
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick   = "CinchBot"
    c.channels = ["#cinch-bots"]
    c.plugins.plugins = [PrivateMessenger]
  end
end

bot.start