require 'cinch'

# Give this bot ops in a channel and it'll auto voice 
# visitors
#
# Enable with !autovoice on
# Disable with !autovoice off

bot = Cinch.setup do
  server "irc.freenode.org"
  channels %w( #cinch )
end
 
autovoice = true

bot.on :join do |m|
  unless m.nick == bot.options.nick # We shouldn't attempt to voice ourselves
    bot.mode(m.channel, '+v', m.nick) if autovoice
  end
end

bot.add_custom_pattern(:onoff, '(on|off)')

bot.plugin "autovoice :option-onoff" do |m|
  case m.args[:option]
    when 'on'; autovoice = true
    when 'off'; autovoice = false
  end
  m.answer "Autovoice is now #{autovoice ? 'enabled' : 'disabled'}"
end

bot.run
