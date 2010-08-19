require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

class Google
  include Cinch::Plugin
  match /google (.+)/

  def search(query)
    url = "http://www.google.com/search?q=#{CGI.escape(query)}"
    res = Nokogiri::HTML(open(url)).at("h3.r")

    title = res.text
    link = res.at('a')[:href]
    desc = res.at("./following::div").children.first.text
  rescue
    "No results found"
  else
    CGI.unescape_html "#{title} - #{desc} (#{link})"
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
