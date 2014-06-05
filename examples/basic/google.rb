require "json"
require 'cgi'
require 'cinch'
require 'open-uri'

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.net"
    c.nick     = "MrCinch"
    c.channels = ["#cinch-bots"]
  end

  helpers do
    def google(search_term)
      argument_string = CGI.escape(search_term)
      open("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{argument_string}") do |http|
        json = JSON.parse(http.read)
        results = json["responseData"]["results"]
        result = results.find {|r| r["GsearchResultClass"] == "GwebSearch"}

        if result.nil?
          return "(no results)"
        end

        return "[%s] %s - %s" % [search_term, result["unescapedUrl"], result["titleNoFormatting"]]
      end
    end
  end

  on :message, /^!google (.+)/ do |m, query|
    m.reply google(query)
  end
end

bot.start
