#!/usr/bin/env ruby

require 'cinch'

bot = Cinch.setup do
  server "irc.freenode.org"
  channels %w( #cinch )
end

class Memo < Struct.new(:nick, :channel, :text, :time)
  def to_s
    "[#{time.asctime}] <#{channel}/#{nick}> #{text}"
  end
end

@memos = {}

bot.on :privmsg do |m|
  if @memos.has_key?(m.nick)
    bot.privmsg m.nick, @memos[m.nick].to_s
    @memos.delete(m.nick)
  end
end

bot.plugin("memo :nick-string :memo") do |m|
  nick = m.args[:nick]

  if @memos.key?(nick)
    m.reply "There's already a memo #{nick}. You can only store one right now"
  elsif nick == m.nick
    m.reply "You can't leave memos for yourself.."
  elsif nick == bot.options.nick
    m.reply "You can't leave memos for me.."
  else
    @memos[nick] = Memo.new(m.nick, m.channel, m.args[:memo], Time.new)
    m.reply "Added memo for #{nick}"
  end
end

bot.run
