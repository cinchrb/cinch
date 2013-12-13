require "cinch"

def check_user( u )
  u == 'i_am_the_op'
end

bot = Cinch::Bot.new do

  configure do | c |
    c.server = "chat.freenode.org"
    c.nick = "bot-op-setter"
    c.channels = [ "#channel" ]
    # c.key = "letmein" # if there is a private key on this channel
  end
  
  on :join do | m |
    m.channel.op( m.user ) if check_user( m.user.nick )
  end
  
end

bot.start
