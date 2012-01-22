require 'open-uri'
require 'cinch'

class TinyURL
  include Cinch::Plugin

  listen_to :channel

  def shorten(url)
    url = open("http://tinyurl.com/api-create.php?url=#{URI.escape(url)}").read
    url == "Error" ? nil : url
  rescue OpenURI::HTTPError
    nil
  end

  def listen(m)
    urls = URI.extract(m.message, "http")
    short_urls = urls.map { |url| shorten(url) }.compact
    unless short_urls.empty?
      m.reply short_urls.join(", ")
    end
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = ["#cinch-bots"]
    c.plugins.plugins = [TinyURL]
  end
end

bot.start
