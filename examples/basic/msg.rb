require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.org"
    c.nick     = "CinchBot"
    c.channels = ["#cinch-bots"]
  end

  on :message, /^!msg (.+?) (.+)/ do |m, who, text|
    User(who).send text
  end
end

bot.start

