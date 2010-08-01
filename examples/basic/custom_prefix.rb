require 'cinch'

bot = Cinch.setup do 
  server "irc.freenode.org"
  channels %w( #cinch )
end

bot.plugin "default" do |m|
  m.reply "default prefix"
end

bot.plugin "custom", :prefix => '@' do |m|
  m.reply "custom prefix"
end

bot.plugin "botnick", :prefix => :botnick do |m|
  m.reply "botnick prefix"
end

bot.plugin "botnick2", :prefix => bot.nick do |m|
  m.reply "another botnick prefix"
end

bot.run

