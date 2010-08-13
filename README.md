Cinch - An IRC Bot Building Framework
=====================================

Description
-----------

Cinch is an IRC Bot Building Framework for quickly creating IRC bots in
Ruby with minimal effort. It provides a simple interface based on plugins and
rules. It's as easy as creating a plugin, defining a rule, and watching your
profits flourish.

Cinch will do all of the hard work for you, so you can spend time creating cool
plugins and extensions to wow your internet peers.

If you'd like to test your own Cinch experiments you can do so in the
\#cinch-bots IRC channel on
[irc.freenode.org](irc://irc.freenode.org/cinch-bots). For general
support, join [#cinch](irc://irc.freenode.org/cinch).

This original document can be found [here](http://doc.injekt.net/cinch).

Installation
------------

### RubyGems

You can install the latest Cinch gem using RubyGems

    gem install cinch

### GitHub

Alternatively you can check out the latest code directly from Github

    git clone http://github.com/injekt/cinch.git

Example
-------

Your typical Hello, World application in Cinch would go something like this:

    require 'cinch'

    bot = Cinch::Bot.new do
      configure do |c|
        c.server = "irc.freenode.org"
        c.channels = ["#cinch-bots"]
      end

      on :message, "hello" do |m|
        m.reply "Hello, #{m.user.nick}"
      end
    end

    bot.start

More examples can be found in the `examples` directory.

Features
--------

#### Documentation

Cinch provides a documented API, which is online for your viewing pleasure [here](http://doc.injekt.net/cinch).

#### Object Oriented

Many IRC bots (and there are, so **many**) are great, but we see so little of them take
advantage of the awesome Object Oriented Interface which most Ruby programmers will have
become accustomed to and grown to love. 

Well, Cinch uses this functionality to it's advantage. Rather than having to pass around
a reference to a channel or a user, to another method, which then passes it to 
another method (by which time you're confused about what's going on) -- Cinch provides
an OOP interface for even the simpliest of tasks, making your code simple and easy 
to comprehend.

#### Threaded

#### Key/Value Store

We have listened to your requests and implemented a bot-wide key/value store. You can
now store data and use it across your handlers. Here's an example:

    configure do |c|
      store[:friends] = []
    end

    on :message, /^add friend (.+)$/ do |m, friend|
      store[:friends] << friend
    end

    on :message /^get friends$/ do |m|
      m.reply "Your friends are: #{store[:friends].join(', ')}"
    end

Neat, right?

#### Plugins

#### Pretty Output

Ever get fed up of watching those boring, frankly unreadable lines flicker down your
terminal screen whilst your bot is online? Help is at hand! By default, Cinch will
colorize all text it sends to a terminal, meaning you get some pretty damn awesome
readable coloured text.

Authors
-------

* [Lee Jarvis](http://injekt.net)
* [Dominik Honnef](http://fork-bomb.org)

Contribute
----------
