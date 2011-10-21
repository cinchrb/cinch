require 'cinch'

class DiceRoll
  include Cinch::Plugin

  # [[<repeats>#]<rolls>]d<sides>[<+/-><offset>]
  match(/roll (?:(?:(\d+)#)?(\d+))?d(\d+)(?:([+-])(\d+))?/)
  def execute(m, repeats, rolls, sides, offset_op, offset)
    repeats = repeats.to_i
    repeats = 1 if repeats < 1
    rolls   = rolls.to_i
    rolls   = 1 if rolls < 1

    total = 0

    repeats.times do
      rolls.times do
        score = rand(sides.to_i) + 1
        if offset_op
          score = score.send(offset_op, offset.to_i)
        end
        total += score
      end
    end

    m.reply "Your dice roll was: #{total}", true
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.freenode.org'
    c.channels = ['#cinch-bots']
    c.plugins.plugins = [DiceRoll]
  end
end

bot.start
