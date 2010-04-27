require 'cinch'

bot = Cinch.setup do 
  server "irc.freenode.org"
  channels %w{ #cinch }
end

bot.add_custom_type(:friends, "(injekt|lee|john|bob)")
bot.add_custom_type(:hex, "([\\dA-Fa-f]+?)")

bot.plugin("I like :person-friends", :prefix => false) do |m|
  m.reply "I like #{m.args[:person]} too!"
end

bot.plugin("checkhex :n-hex") do |m|
  m.answer "Yes, #{m.args[:n]} is indeed hex."
end

bot.run

