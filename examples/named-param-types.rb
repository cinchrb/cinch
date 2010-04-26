require '/home/injekt/code/cinch/lib/cinch'
require 'pp'

bot = Cinch.setup do
  server "irc.freenode.org"
  channels %w( #cinch )
end

bot.plugin("say :n-digit :text") do |m|
  m.args[:n].to_i.times {
    m.reply m.args[:text]
  }
end

bot.plugin("say :text-word :rest") do |m|
  stuff = [m.args[:text], m.args[:rest]].join(' ')
  m.reply stuff
end

bot.run
