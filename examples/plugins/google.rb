require "json"
require 'cgi'
require 'cinch'
require 'open-uri'

class Google
  include Cinch::Plugin

  match(/google (.+)/)
  def execute(m, search_term)
    argument_string = CGI.escape(search_term)
    open("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{argument_string}") do |http|
      json = JSON.parse(http.read)
      results = json["responseData"]["results"]
      result = results.find {|r| r["GsearchResultClass"] == "GwebSearch"}

      if result.nil?
        m.reply "(no results)"
        return
      end

      m.safe_reply "[%s] %s - %s" % [search_term, result["unescapedUrl"], result["titleNoFormatting"]]
    end
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
