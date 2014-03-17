require 'cinch'

# Who should be able to access these plugins
$admin = "injekt"

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.org"
    c.nick     = "CinchBot"
    c.channels = ["#cinch-bots"]
  end

  helpers do
    def is_admin?(user)
      true if user.nick == $admin
    end
  end

  on :message, /^!join (.+)/ do |m, channel|
    bot.join(channel) if is_admin?(m.user)
  end

  on :message, /^!part(?: (.+))?/ do |m, channel|
    # Part current channel if none is given
    channel = channel || m.channel

    if channel
      bot.part(channel) if is_admin?(m.user)
    end
  end
end

bot.start

