# @title Migration Guide
# Migration Guide

This document explains how to migrate between API incompatible
versions of Cinch.

## Migrating from 1.x to 2.x

## Plugins

### Plugin options

Previously, plugins used a DSL-like way of setting options like the
plugin prefix. This contradicts with the general idea of plugins being
ordinary Ruby classes and also caused a lot of code and documentation
smell.

Instead of having methods like `#prefix` double as both attribute
getter and setter, options can now be set in two different ways: Using
ordinary attribute setters or using the
{Cinch::Plugin::ClassMethods#set #set} method.

#### Cinch 1.x

    class MyPlugin
      include Cinch::Plugin

      prefix /^!/
      help "some help message"
      match /foo/
      def execute(m)
        # ...
      end
    end

#### Cinch 2.x, attribute setters

    class MyPlugin
      include Cinch::Plugin

      self.prefix = /^!/
      self.help   = "some help message"
      match /foo/
      def execute(m)
        # ...
      end
    end

#### Cinch 2.x, `#set` method

    class MyPlugin
      include Cinch::Plugin

      set :prefix, /^!/
      set :help,   "some help message"
      match /foo/
      def execute(m)
        # ...
      end
    end

#### Cinch 2.x, `#set` method, alternative syntax

    class MyPlugin
      include Cinch::Plugin

      set prefix: /^!/,
          help:   "some help message"
      match /foo/
      def execute(m)
        # ...
      end
    end


### No more automatic matcher with the plugin's name

Cinch does not add a default matcher with the plugin's name anymore.
If you've been relying on the following to work

    class Footastic
      include Cinch::Plugin

      def execute(m)
        # this will triger on "!footastic"
      end
    end

you will have to rewrite it using an explicit matcher:

    class Footastic
      include Cinch::Plugin

      match "footastic"
      def execute(m)
        # ...
      end
    end

### No more default `#execute` and `#listen` methods

Plugins do not come with default `#execute` and `#listen` methods
anymore, which means that specifying a matcher or listener without
providing the required methods will always result in an exception.

### Programmatically registering plugins

If you're using the API to register plugins on your own, you will have
to use the new {Cinch::PluginList} class and its methods, instead of
using `Cinch::Bot#register_plugin`/`Cinch::Bot#register_plugins`,
which have been removed.

The PluginList instance is available via {Cinch::Bot#plugins}

## Logging

Logging in Cinch 2.x has been greatly improved. Instead of only
supporting one logger and having all logging-relevant methods in
{Cinch::Bot}, we've introduced the {Cinch::LoggerList} class, which
manages an infinite number of loggers. Included with Cinch are the
{Cinch::Logger::FormattedLogger formatted logger}, known from Cinch
1.x, and a new {Cinch::Logger::ZcbotLogger Zcbot logger}, a logger
emulating the log output of Zcbot, a format which can be parsed by
{http://pisg.sourceforge.net/ pisg}.

### Log levels

The old `@config.verbose` option has been replaced with a finely
tunable log level system. Each logger has {Cinch::Logger#level its own
level}, but it is also possible to {Cinch::LoggerList#level= set the
level for all loggers at once}.

The available levels, in ascending order of verbosity, are:

- fatal
- error
- warn
- info
- log
- debug

### Methods

All logging related methods (`Cinch::Bot#debug` et al) have been
removed from the Bot class and instead moved to the loggers and the
{Cinch::LoggerList LoggerList}. If you want to log messages from your
plugins or handlers, you should use {Cinch::Bot#loggers} to access the
{Cinch::LoggerList LoggerList} and then call the right methods on that.

## `Bot#dispatch`

## Prefix/matcher + string semantics

## *Manager → *List

## Hooks and their return value

## Constants

All constants for numeric replies (e.g. `RPL_INFO`) have been moved from
`Cinch` to `Cinch::Constants`. Thus `Cinch::RPL_INFO` becomes
{Cinch::Constants::RPL_INFO}, same for all other numeric constants.

## Configuration namespace

## Various removed methods

### `Bot#raw`, `IRC#message`

Use {Cinch::IRC#send} instead.

### `Bot#msg`, `Bot#notice`, `Bot#safe_msg`, `Bot#safe_notice`, `Bot#action`, `Bot#safe_action`

These methods have been moved to the {Cinch::Target Target} class, whose direct
descendants are {Cinch::User User} and {Cinch::Channel Channel}.

### Removed `halt` method

`halt` was being used for breaking out of `on`-handlers early. The same
thing can be achieved with `break`/`next`.

### Bot#dispatch

### UserList/ChannelList

## `@config.verbose`

## `on`-handlers now only accepts one pattern

In previous versions, {Cinch::Bot#on} accepted a variable amount of patterns
to match against. This feature was rarely used and has hence been
removed. If you've been using constructs like

    on :message, [/this/, /that/] do |m|
      # ...
    end

you will have to rewrite them as follows:

    b = lambda { |m|
      # ...
    }

    [/this/, /that/].each do |pattern|
      on :message, pattern, &b
    end
