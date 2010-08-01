require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

# This bot connects to urban dictionary and returns the first result
# for a given query, replying with the result directly to the sender

bot = Cinch.setup do 
  server "irc.freenode.net"
  nick "MrCinch"
  channels %w/ #cinch /
end

# This method assumes everything will go ok, it's not the best method
# of doing this *by far* and is simply a helper method to show how it
# can be done.. it works!
def urban_dict(query)
  url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(query)}"
  CGI.unescape_html Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/, ' ') rescue nil
end

bot.plugin("urban :query") do |m|
  m.answer urban_dict(m.args[:query]) || "No results found"
end

bot.run

# injekt> !urban cinch
# MrCinch> injekt: describing an action that's extremely easy.

