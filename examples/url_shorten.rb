require 'open-uri'
require 'cinch'

# Automatically shorten URL's found in messages
# Using the tinyURL API

bot = Cinch.configure do
  server "irc.freenode.org"
  verbose true
  channels %w/#cinch/
end

def shorten(url)
  url = open("http://tinyurl.com/api-create.php?url=#{URI.escape(url)}").read
  url == "Error" ? nil : url
rescue OpenURI::HTTPError
  nil
end

bot.on :privmsg do |m|
  unless m.private?
    urls = URI.extract(m.text, "http")

    unless urls.empty?
      short_urls = urls.map {|url| shorten(url) }.compact

      unless short_urls.empty?
        m.reply short_urls.join(", ")
      end
    end
  end
end

bot.start
