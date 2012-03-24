# @title Getting Started
# @markup kramdown

# Getting Started

This short guide will show you how to easily and quickly write your
own IRC bot with Cinch.

# What Cinch really is

First and foremost, it is important to understand that Cinch is more
of an API for IRC access than a full-blown bot framework like Autumn
or Rbot.

There will be no enforced directory structures, no magical places from
which plugins will be loaded and no obscure, "fancy" names. Plugins
will be plugins and not "leaves".

This, however, does not mean that Cinch requires you to be familiar
with the internals of the IRC protocol. Quite the opposite: A very
high-level abstraction is provided, allowing things such as

    Channel("#cinch").users.each do |user, modes|
      user.send "I am watching you!"
    end

to work.


Furthermore, the API has been designed in a way that it sticks true to
the way Ruby looks and behaves. Plugins are normal classes that mix-in
a module, functions of the bot are implemented as normal methods and
so on.

# Hello, World

The following will describe one of the most basic IRC bots you can
write in Cinch: One that joins a specific channel and responds to
"hello" by saying "Hello, World".


    require "cinch"

    bot = Cinch::Bot.new do
      configure do |c|
        c.server   = "irc.freenode.net"
        c.channels = ["#cinch-bots"]
      end

      on :message, "hello" do |m|
        m.reply "Hello, World"
      end
    end

    bot.start


Note that this is the entire file and all you need for the basic bot
to work. Save the above example to a file and run it with Ruby.

## In Detail

So, what are we actually doing in that short piece of code? First, we
create a new bot in line 3 and conigure it in lines 4–6 –
{Cinch::Bot#configure configure} simply yields the configuration
object, which allows you to configure various things. In this example,
we only set which server to connect to and which channel to join.
Another often-used option is the nickname of the bot
({file:docs/bot_options.md#nick c.nick}). For an overview of all
available options, see {file:docs/bot_options.md the list of options}.

Following, we define a basic message handler. In its simplest form,
{Cinch::Bot#on on} expects two arguments: The kind of message to react
to and the pattern to match. In this case, the kind is
{file:docs/events.md#message :message}, which means that the bot will
respond to both messages in channels as well as messages sent directly
to the bot. For a list of all kinds, called events, see
{file:docs/events.md the list of events}.

For the pattern we use a basic string, which means that the message
has to be exactly that string. It mustn't have anything before or
after the word "hello". Another way of using {Cinch::Bot#on on} is by using
regular expressions:

    on :message, /^\d{4}$/ do |m|
      # ...
    end

will match all messages that consist of exactly four digits and
nothing else.

Whenever a message matches the handler we just defined, the block we
provided will be called, with the message object, and optionally
capture groups of the regular expression, passed to it.

The message object allows insight into the nature of the message, i.e.
who sent it, when was it sent etc, and also provides the
{Cinch::Message#reply reply} method, an easy way of responding to a
message. If the message was sent to a channel, {Cinch::Message#reply
reply} will respond to the channel, otherwise directly to the user.

We then use exactly that {Cinch::Message#reply reply} method to send back "Hello, World"
whenever someone says "hello".

That's it!

# on-handlers vs. plugins

Using `on` might be nice and handy for writing simple bots, but if you
want to write a more complex bot, providing lots of different features
to its users, then using plugins might be a better solution.

But what are plugins, exactly? Technically, plugins are implemented as
Ruby classes that mix-in a {Cinch::Plugin specific module} to get
access to various methods.

To have an example to work with, we'll convert our "Hello, World" bot
to using the plugin API:

    require "cinch"

    class HelloWorld
      include Cinch::Plugin

      match "hello"
      def execute(m)
        m.reply "Hello, World"
      end
    end

    bot = Cinch::Bot.new do
      configure do |c|
        c.server = "irc.freenode.net"
        c.channels = ["#cinch-bots"]
        c.plugins.plugins = [HelloWorld]
      end
    end

    bot.start

The first thing to notice is that we wrote a new class called
`HelloWorld`, and that we use {Cinch::Plugin::ClassMethods#match
match} instead of `on` to define our handler. Furthermore, we didn't
specify a message type nor did we provide any blocks.

But let's back up and proceed in smaller steps to see how plugins are built.

First thing after defining a new class is to include {Cinch::Plugin} –
This module will provide methods like
{Cinch::Plugin::ClassMethods#match match} and also allows Cinch to
control the class in specific ways required for plugins to work.

Then we use aforementioned `match`, instead of `on`, to specify what
messages we want to react to. We didn't have to specify the message
type because plugins default to {file:docs/events.md#message :message}.

We then define a method called `execute`, which is pretty much the
same as blocks are to on-handlers. And from here on, everything is the
same.

The only thing left to do is to tell Cinch to use our plugin, by
adding it to {file:docs/bot_options.md#pluginsplugins c.plugins.plugins}.

One important thing remains to note: Plugins have a
{file:docs/bot_options.md#pluginsprefix prefix}, a string (or pattern)
that gets appended to all patterns you define, and by default this
prefix is `/^!/`. This means that in order to invoke our HelloWorld
plugin, a user has to say "!hello" instead of "hello". This prefix can
be configured on a per-plugin or global basis, but that's not in the
scope of this document.

# Final Words

This short guide only explains the basics of using Cinch, so that you
can get started as quickly as possible. For more advanced topics, you
will want to read the specific documents:

- {file:docs/plugins.md Plugins}
- {file:docs/bot_options.md A list of all available bot options}
- {file:docs/events.md A list of all available events}
- {file:docs/encodings.md Dealing with encodings}
- {file:docs/logging.md Logging in Cinch}
- {file:docs/common_tasks.md A cookbook for common tasks}
- {file:docs/common_mistakes.md A list of common mistakes and how to avoid them}
