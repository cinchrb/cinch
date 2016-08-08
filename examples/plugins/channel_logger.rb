# This plugin logs private messages and each channel seperately.
# Intended use would be to pipe Cinch::Loggers STDOUT/STDERR to a
# debug log and ChannelLogger mail to will handle the rest.
# I'm sure fixing up the Cinch::Logger(s)? class is the solution,
# but this is a good temporary fix.

require 'cinch'

# Message instance variable message needs to be writeable
module Cinch; class Message; attr_accessor :message ; end; end

class ChannelLogger
  include Cinch::Plugin

  set :required_options, [:logfile]

  listen_to :connect,            :method => :setup
  listen_to :disconnect,         :method => :cleanup

  listen_to :channel,            :method => :log_public_message
  listen_to :private,            :method => :log_private_message
  listen_to :error, :action,
  :join, :leaving,               :method => :handle_notice

  def setup(*args)
    @logs               = { :privmsg =>File.open(config[:logfile], "a") }
    @logs[:privmsg].sync  = true
    @logdir             = File.dirname(config[:logfile])
    @timeformat         = config[:timeformat]       || "%Y/%m/%d %H:%M:%S"
    @logformat          = config[:format]           || "[%{time}] %{channel} %{nick}: %{msg}"
    @last_time_check    = Time.now

    bot.debug("Opened message logfile at #{config[:logfile]}")
  end

  def handle_notice(msg, *args)
    h = msg.raw.strip.split(/\s+/)[1]
    if h =~ /JOIN/ and msg.channel
      open_log(msg.channel.name)
    end
    msg.message = "-!- [#{h.to_s}] #{msg.user.nick}"
    log_public_message(msg)
  end

  def log_public_message(msg)
    return unless @logs # Connection messages will still go to logger
    log_msg(msg)
  end

  def log_private_message(msg)
    return unless msg.respond_to?(:user)
    log_public_message(msg)
  end

  def cleanup(*)
    @logs.each_pair{ |key, fh|
      fh.puts(sprintf(@logformat,
              :time => Time.now.strftime(@timeformat),
              :channel => key.to_s,
              :nick    => bot.nick,
              :msg     => "-!- [QUIT] #{bot.nick}"))

      fh.close
    }
    bot.debug("Closed message logfiles.")
  end

  private
  def log_msg(msg)
    chl = msg.channel || :privmsg
    @logs[chl].puts(sprintf(@logformat,
                    :time    => Time.now.strftime(@timeformat),
                    :channel => chl.to_s,
                    :nick    => msg.user.nick,
                    :msg     => msg.message ))
  end

  def open_log(chl)
    @logs[chl]      ||=
      File.open("#{@logdir}/#{chl}.log", "a")
    @logs[chl].sync ||= true
  end

end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "channel_logger"
    c.server          = "irc.freenode.org"
    c.channels        = ["#cinch-bots"]

    c.plugins.options[ChannelLogger] = {
      :logfile => '/tmp/private_msgs.log'
    }

    c.plugins.plugins = [ChannelLogger]
  end
end

bot.start
