#!/usr/bin/env ruby

require 'cinch'
require 'cinch/storage/yaml'

class Memo
  class MemoStruct < Struct.new(:user, :channel, :text, :time)
    def to_s
      "[#{time.asctime}] <#{channel}/#{user}> #{text}"
    end
  end

  include Cinch::Plugin

  def initialize(*args)
    super
    storage[:memos] ||= {}
  end

  listen_to :message
  match /memo (.+?) (.+)/

  def listen(m)
    if storage[:memos].has_key?(m.user.nick)
      m.user.send storage[:memos].delete(m.user.nick).to_s
      storage.save
    end
  end

  def execute(m, nick, message)
    if storage[:memos].key?(nick)
      m.reply "There's already a memo for #{nick}. You can only store one right now"
    elsif nick == m.user.nick
      m.reply "You can't leave memos for yourself.."
    elsif nick == bot.nick
      m.reply "You can't leave memos for me.."
    else
      storage[:memos][nick] = MemoStruct.new(m.user.name, m.channel.name, message, Time.now)
      storage.save
      m.reply "Added memo for #{nick}"
    end
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = ["#cinch-bots"]
    c.plugins.plugins = [Memo]
    c.storage.backend = Cinch::Storage::YAML
    c.storage.basedir = "./yaml/"
    c.storage.autosave = true
  end
end

bot.start
