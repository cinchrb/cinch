# @title Logging
# @markup kramdown

# Using the logger

Plugins can use the logging facility for logging their own messages,
either by using the logging related helper methods (#debug, #info, and
so on) or by directly interfacing with {Cinch::LoggerList}, which is
available via `@bot.loggers`.

Example:

    class MyPlugin
      include Cinch::Plugin

      match "foo"
      def execute(m)
        debug "Starting handler..."
        info  "Some more important information"
        debug "Done."
      end
    end

# Logger levels

Cinch uses a priority-based logging system, using the types `:debug`,
`:log`, `:info`, `:warn`, `:error` and `:fatal`, each of them
displaying less information than the previous.

By default, the logging level to display is set to `:debug`, which
will include all possible kinds of log events, including the rather
verbose debug output caused by plugins.

`:log` will hide debug output but still contain the raw IRC log and
from there on, the levels are rather self-explanatory.

## Changing the level

The level can be changed for single loggers or all loggers at once, by either using {Cinch::Logger#level=} or {Cinch::LoggerList#level=} respectively.

Example:

    bot = Cinch::Bot.new { }
    bot.loggers << Cinch::Logger::FormattedLogger.new(File.open("/tmp/log.log", "a"))
    bot.loggers.level = :debug
    bot.loggers.first.level  = :info

This will set all loggers to the `:debug` level (which actually is the
default already) and the first logger (which is the default STDOUT
logger) to `:info`.

# Writing your own logger

This section will follow soon. For now just look at the code of
already implemented loggers.
