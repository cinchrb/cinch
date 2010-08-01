require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

bot = Cinch.setup do 
  server "irc.freenode.net"
  nick "MrCinch"
  channels %w/ #cinch /
end

# Extremely basic method, grabs the first result returned by Google
# or "No results found" otherwise
def google(query)
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

bot.plugin("google :query") do |m|
  m.reply google(m.args[:query])
end

bot.run
