require 'cinch'

class DirectAddressing
  include Cinch::Plugin

  # Note: the lambda will be executed in the context it has been
  # defined in, in this case the class DirectAddressing (and not an
  # instance of said class).
  #
  # The reason we are using a lambda is that the bot's nick can change
  # and the prefix has to be up to date.
  set :prefix, lambda{ |m| Regexp.new("^" + Regexp.escape(m.bot.nick + ": " ))}

  match "hello", method: :greet
  def greet(m)
    m.reply "Hello to you, too."
  end

  match "rename", method: :rename
  def rename(m)
    @bot.nick += "_"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "cinch_lambda"
    c.server          = "irc.freenode.org"
    c.channels        = ["#cinch-bots"]
    c.verbose         = true
    c.plugins.plugins = [DirectAddressing]
  end
end

bot.start
