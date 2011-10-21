require 'cinch'

class DiceRoll
    include Cinch::Plugin
    
    match /roll/
    
    def execute(m)
        roll = (Random.new).rand(1..6)
        m.reply "Your dice roll was #{roll}", true
    end
end

bot = Cinch::Bot.new do
    configure do |c|
        c.server = 'irc.freenode.org'
        c.channels = [ '#cinch-bots' ]
        c.plugins.plugins = [ DiceRoll ]
    end
end

bot.start
