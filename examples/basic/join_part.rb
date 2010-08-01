require 'cinch'

bot = Cinch.setup do 
  server "irc.freenode.org"
  nick "CinchBot"
  channels %w( #cinch )
end

# Who should be able to access these plugins
admin = 'injekt'

bot.plugin "join :channel", :nick => admin do |m|
  bot.join m.args[:channel]
end

bot.plugin "part :channel", :nick => admin do |m|
  bot.part m.args[:channel]
end

# Part current channel if none is given
bot.plugin "part", :nick => admin do |m|
  bot.part m.channel
end

bot.run

