require 'open-uri'
require 'cinch'

# Automatically shorten URL's found in messages
# Using the tinyURL API

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.org"
    c.channels = ["#cinch-bots"]
    c.nick = "cinch"
  end

  helpers do
    def shorten(url)
      if url.length < 79
        return nil
      end
      url = open("http://tinyurl.com/api-create.php?url=#{URI.escape(url)}").read
      url == "Error" ? nil : url
    rescue OpenURI::HTTPError
      nil
    end
  end

  on :channel do |m|
    urls = URI.extract(m.message, ["http","https"])

    unless urls.empty?
      short_urls = urls.map {|url| shorten(url) }.compact
      doc = Pismo::Document.new(urls[0])
      title = doc.title
      unless short_urls.empty?
        m.reply m.user.nick + ": " + short_urls.join(", ") + " Title: '" + title +"'" 
      end
    end
  end
end

bot.start
