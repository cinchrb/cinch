require 'cinch'

bot = Cinch.setup do 
  server "irc.freenode.org"
  channels %w( #cinch )
end

bot.plugin "hello" do |m|
  m.reply "Hello, #{m.nick}!"
end

bot.run

