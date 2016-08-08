require 'logger'
require 'cinch'
require 'cinch/logger/zcbot_logger'
class OutputLogger < Logger
  def puts(msg)
    info(msg)
  end
end
class RegularOutputLogger < OutputLogger
  def puts(msg)
    super if msg =~ /\AREGULAR/
  end
end
class MessageOutputLogger < OutputLogger
  def puts(msg)
    super unless msg =~ /\AREGULAR/
  end
end
class MessageLogger < Cinch::Logger
  def initialize(filename, logger=OutputLogger)
    super(filename)
    @output = logger.new(filename)
    output.formatter =  proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
  end

  def log(messages, event, level=event)
    messages = Array(messages).map do |m|
      if m.is_a?(Cinch::Message)
      # next unless m.command == 'PRIVMSG'
        [m.command, m.channel, m.user, m.message].map(&:to_s).join("\t")
      else
        "REGULAR: #{m}"
      end
    end.compact
    super
  end
end
bot = Cinch::Bot.new do
  def regular_output_logger
    log_path = File.expand_path('../irc-regular.log', __FILE__)
    logger = RegularOutputLogger
    MessageLogger.new(log_path, logger)
  end
  def message_output_logger
    log_path = File.expand_path('../irc-messages.log', __FILE__)
    logger = MessageOutputLogger
    MessageLogger.new(log_path, logger)
  end
  self.loggers.clear
  self.loggers << regular_output_logger
  self.loggers << message_output_logger
  configure do |c|
    c.server = "irc.freenode.org"
    c.nick   = 'irclogger'
    c.verbose = false

    c.channels = %w(#rails-contrib #rubylang)

  end

  on :message  do |m|
    incoming m
  end
end

bot.start
