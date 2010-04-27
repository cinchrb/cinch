require 'cinch'

users = {}

class Seen < Struct.new(:who, :where, :what, :time)
  def to_s
    "[#{time.asctime}] #{who} was seen in #{where} saying #{what}"
  end
end

bot = Cinch.setup(
  :server => 'irc.freenode.org',
  :channels => ['#cinch'],
  :prefix => '!',
  :verbose => true,
)

# Only log a PRIVMSG
bot.on :privmsg do |m|
  # Dont record a private message
  unless m.private?
    users[m.nick] = Seen.new(m.nick, m.channel, m.text, Time.new)
  end
end

bot.plugin("seen :nick") do |m|
  nick = m.args[:nick]

  if nick == bot.nick
    m.reply "That's me!"
  elsif nick == m.nick
    m.reply "That's you!"
  elsif users.key?(nick)
    m.reply users[nick].to_s
  else
    m.reply "I haven't seen #{nick}"
  end
end

bot.run

