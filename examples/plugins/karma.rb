require 'cinch'

class Karma
  include Cinch::Plugin

  match /(\S+)\+{2}/

  def initialize(*args)
    super
    @users = Hash.new(0)
  end

  def execute(m)
    cmd = m.params[1]
    nick = cmd.match(/[a-z_\-\[\]\\^{}|][a-z0-9_\-\[\]\\^{}|]*/)[0]
    if nick == @bot.nick
      m.reply "Increasing my karma would result in overflow."
    elsif nick == m.user.nick
      m.reply "Just keep patting yourself on the back there, sport."
    else
      m.reply "#{ nick } has #{ @users[nick] += 1 } awesome points."
    end
  end
end
