require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class Google
  include Cinch::Plugin
  match /google (.+)/

  def search(query)
    url = "https://www.google.com/search?q=#{CGI.escape(query)}"
    res = Nokogiri::HTML(open(url)).at(".s")

    title = res.at('cite b').text
    link = res.at('cite').text
    desc = res.at('.st').text
    CGI.unescape_html "#{title} - #{desc} (#{link})".dup.force_encoding('binary')
  rescue
    "No results found"
  end

  def execute(m, query)
    m.reply(search(query))
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.net"
    c.nick   = "MrCinch"
    c.channels = ["#cinch-bots"]
    c.plugins.plugins = [Google]
  end
end

bot.start
