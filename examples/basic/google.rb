require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.net"
    c.nick     = "MrCinch"
    c.channels = ["#cinch-bots"]
  end

  helpers do
    # Extremely basic method, grabs the first result returned by Google
    # or "No results found" otherwise
    def google(query)
      url = "https://www.google.com/search?q=#{CGI.escape(query)}"
      res = Nokogiri::HTML(open(url)).at(".s")

      title = res.at('cite b').text
      link = res.at('cite').text
      desc = res.at('.st').text
      CGI.unescape_html "#{title} - #{desc} (#{link})".dup.force_encoding('binary')
    rescue
      "No results found"
    else
      CGI.unescape_html "#{title} - #{desc} (#{link})".dup.force_encoding('binary')
    end
  end

  on :message, /^!google (.+)/ do |m, query|
    m.reply google(query)
  end
end

bot.start
