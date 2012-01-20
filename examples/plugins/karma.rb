require 'cinch'

class Karma
  include Cinch::Plugin

  match /[a-z_\-\[\]\\^{}|][a-z0-9_\-\[\]\\^{}|]*[+][+]/

  def initialize(*args)
    super
    @users = {}
  end

  def execute(m)
    cmd = m.params[1]
    nick = cmd.match(/[a-z_\-\[\]\\^{}|][a-z0-9_\-\[\]\\^{}|]*/)[0]
    if nick == @bot.nick
      m.reply "Increasing my karma would result in overflow."
    elsif nick == m.user.nick
      m.reply "Just keep patting yourself on the back there, sport."
    elsif @users.key? nick
      @users[nick] += 1
      m.reply "#{ nick } has #{ @users[nick] } awesome points."
    else
      @users[nick] = 1
      m.reply "#{ nick } has #{ @users[nick] } awesome points."
    end
  end
end
