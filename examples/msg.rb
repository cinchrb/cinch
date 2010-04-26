require 'cinch'

bot = Cinch.setup do 
  server "irc.freenode.org"
  nick "CinchBot"
  channels %w/ #cinch /
end

bot.plugin("msg :who :text") do |m|
  bot.privmsg m.args[:who], m.args[:text]
end

bot.run

