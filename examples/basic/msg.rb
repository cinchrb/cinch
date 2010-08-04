require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick   = "CinchBot"
  end

  on :connect do
    bot.join "#dominikh"
  end

  on :message, /^!msg (.+?) (.+)/ do |m, who, text|
    User(who).send text
  end
end

bot.start

