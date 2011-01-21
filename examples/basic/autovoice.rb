require 'cinch'

# Give this bot ops in a channel and it'll auto voice
# visitors
#
# Enable with !autovoice on
# Disable with !autovoice off

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "cinch_autovoice"
    c.server          = "irc.freenode.org"
    c.verbose         = true
    c.channels        = ["#cinch-bots"]

    @autovoice        = true
  end

  on :join do |m|
    unless m.user.nick == bot.nick # We shouldn't attempt to voice ourselves
      m.channel.voice(m.user) if @autovoice
    end
  end

  on :channel, /^!autovoice (on|off)$/ do |m, option|
    @autovoice = option == "on"

    m.reply "Autovoice is now #{@autovoice ? 'enabled' : 'disabled'}"
  end
end

bot.start
