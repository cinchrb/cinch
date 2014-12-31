# @title What has changed?
# @markup kramdown

# What has changed in 2.2?

## Getting rid of CP1252 in favour of UTF-8

In versions before 2.2, when using the `irc` encoding (the default),
Cinch would use CP1252 for outgoing messages, only falling back to
UTF-8 if a message wouldn't fit into CP1252. This is a so called
hybrid encoding, which is used by X-Chat and the like.

This encoding, however, is based on the state of 10 years ago, where
the most popular IRC clients, such as mIRC, weren't capable of
handling UTF-8. Nowadays, there are more clients that support UTF-8
than there are clients that can deal with this hybrid encoding, or
CP1252 itself. That's why, from now on, we will always use UTF-8.

If you depend on outgoing messages being encoded in CP1252, please see
{file:docs/encodings.md} on how to change the encoding.

## API improvements

### New methods

- {Cinch::Channel#remove} has been added to support the non-standard
REMOVE command, a friendlier alternative to kicking people.

- {Cinch::Helpers.sanitize} and {Cinch::Formatting.unformat} have been
  added to help with removing unprintable characters and mIRC
  formatting codes from strings.

### Deprecated methods

In order to reduce the amount of aliases, the following ones have been
deprecated and will be removed in a future release:

- {Cinch::Channel#msg}
- {Cinch::Channel#privmsg}
- {Cinch::Target#msg}
- {Cinch::Target#privmsg}
- {Cinch::Target#safe_msg}
- {Cinch::Target#safe_privmsg}
- {Cinch::User#whois}
- {Cinch::Helpers#Color}

Additionally, the following method is deprecated and will be removed
in the future:

- {Cinch::Channel#to_str}

# What has changed in 2.1?
1. Color stripping
1. Per group hooks
1. API improvements
   1. New methods
   1. Changed methods
   1. New aliases

## Color stripping

The new method <del>`Cinch::Utilities::String.strip_colors`</del>
{Cinch::Formatting.unformat} allows removal of mIRC color codes from
messages.

Additionally, a new match option called `strip_colors` makes it
possible to automatically and temporarily strip color codes before
attempting to match a message.

## Per group hooks

A new option `group` for hooks allows registering hooks for specific
groups.

## API improvements

### New methods

#### {Cinch::Bot}

- {Cinch::Bot#oper}

#### {Cinch::User}

- {Cinch::User#oper?}

#### {Cinch::Message}

- {Cinch::Message#action_reply}
- {Cinch::Message#safe_action_reply}

### Changed methods

#### {Cinch::Handler}

- {Cinch::Handler#call} now returns the started thread.

#### {Cinch::HandlerList}

- {Cinch::HandlerList#dispatch} now returns the started threads.

### New aliases

Due to some unfortunate naming mistakes in Cinch 2.0, Cinch 2.1 adds
several aliases. All of the new aliases deprecate the original method
names, which will be removed in Cinch 3.0.

#### {Cinch::User}
- {Cinch::User#monitored?} for {Cinch::User#monitored}
- {Cinch::User#synced?} for {Cinch::User#synced}



# What has changed in 2.0?
1. Added support for SASL
1. Added support for DCC SEND
1. Added a fair scheduler for outgoing messages
1. Added required plugin options
1. Added support for colors/formatting
1. Added network discovery
1. Added match groups
1. Added match options overwriting plugin options
1. Added support for actions (/me)
1. Added support for broken IRC networks
1. Dynamic timers
1. Reworked logging facilities
1. API improvements
   1. Helper changes
   1. Added a Cinch::Target Target class
   1. Cinch::Constants
   1. New methods
   1. Removed/Renamed methods
   1. Handlers
   1. The Plugin class
   1. Channel/Target/User implement Comparable
   1. Renamed `*Manager` to `*List`
1. New events

## Added support for SASL

Cinch now supports authenticating to services via SASL. For more
information check {Cinch::SASL}.

## Added support for DCC SEND

Support for sending and receiving files via DCC has been added to
Cinch. Check {Cinch::DCC} for more information.

## Added a fair scheduler for outgoing messages
Cinch always provided sophisticated throttling to avoid getting kicked
due to _excess flood_. One major flaw, however, was that it used a
single FIFO for all messages, thus preferring early message targets
and penalizing later ones.

Now Cinch uses a round-robin approach, having one queue per message
target (channels and users) and one for generic commands.

## Added required plugin options

Plugins can now require specific options to be set. If any of those
options are not set, the plugin will automatically refuse being
loaded.

This is useful for example for plugins that require API keys to
interact with web services.

The new attribute is called
{Cinch::Plugin::ClassMethods#required_options required_options}.

Example:

    class MyPlugin
      include Cinch::Plugin

      set :required_options, [:foo, :bar]
      # ...
    end

    # ...

    bot.configure do |c|
      c.plugins.plugins = [MyPlugin]
      c.plugins.options[MyPlugin] = {:foo => 1}
    end

    # The plugin won't load because the option :bar is not set.
    # Instead it will print a warning.

## Added support for colors/formatting

A new {Cinch::Formatting module} and {Cinch::Helpers#Format helper}
for adding colors and formatting to messages has been added. See the
{Cinch::Formatting module's documentation} for more information on
usage.

## Added support for network discovery

Cinch now tries to detect the network it connects to, including the
running IRCd. For most parts this is only interesting internally, but
if you're writing advanced plugins that hook directly into IRC and
needs to be aware of available features/quirks, check out
{Cinch::IRC#network} and {Cinch::Network}.

## Reworked logging facilities

The logging API has been drastically improved. Check the
{file:docs/logging.md logging documentation} for more information.


## Added match groups

A new option for matchers, `:group`, allows grouping multiple matchers
to a group. What's special is that in any group, only the first
matching handler will be executed.

Example:

    class Foo
      include Cinch::Plugin

      match /foo (\d+)/, group: :blegh, method: :foo1
      match /foo (.+)/,  group: :blegh, method: :foo2
      match /foo .+/,                   method: :foo3
      def foo1(m, arg)
        m.reply "foo1"
      end

      def foo2(m, arg)
        m.reply "foo2"
      end

      def foo3(m)
        m.reply "foo3"
      end
    end
    # 02:05:39       dominikh │ !foo 123
    # 02:05:40          cinch │ foo1
    # 02:05:40          cinch │ foo3

    # 02:05:43       dominikh │ !foo bar
    # 02:05:44          cinch │ foo2
    # 02:05:44          cinch │ foo3


## Added match options overwriting plugin options

Matchers now have their own `:prefix`, `:suffix` and `:react_on`
options which overwrite plugin options for single matchers.


## Added support for actions (/me)

A new event, {`:action`} has been added and can be used for matching
actions as follows:

    match "kicks the bot", react_on: :action
    def execute(m)
      m.reply "Ouch!"
    end

## API improvements

### Helper changes

The helper methods {Cinch::Helpers#User User()} and
{Cinch::Helpers#Channel Channel()} have been extracted from
{Cinch::Bot} and moved to {Cinch::Helpers their own module} which can
be reused in various places.

### Added a {Cinch::Target Target} class

Since {Cinch::Channel} and {Cinch::User} share one common interface
for sending messages, it only makes sense to have a common base class.
{Cinch::Target This new class} takes care of sending messages and
removes this responsibility from {Cinch::Channel}, {Cinch::User} and
{Cinch::Bot}

### {Cinch::Constants}

All constants for IRC numeric replies (`RPL_*` and `ERR_*`) have been
moved from {Cinch} to {Cinch::Constants}

### New methods

#### {Cinch::Bot}

- {Cinch::Bot#channel_list}
- {Cinch::Bot#handlers}
- {Cinch::Bot#loggers}
- {Cinch::Bot#loggers=}
- {Cinch::Bot#modes}
- {Cinch::Bot#modes=}
- {Cinch::Bot#set_mode}
- {Cinch::Bot#unset_mode}
- {Cinch::Bot#user_list}

#### {Cinch::Channel}

- {Cinch::Channel#admins}
- {Cinch::Channel#half_ops}
- {Cinch::Channel#ops}
- {Cinch::Channel#owners}
- {Cinch::Channel#voiced}

#### {Cinch::Helpers}

- {Cinch::Helpers#Target} -- For creating a {Cinch::Target Target} which can receive messages
- {Cinch::Helpers#Timer}  -- For creating new timers anywhere
- {Cinch::Helpers#rescue_exception} -- For rescueing and automatically logging an exception
- {Cinch::Helpers#Format} -- For adding colors and formatting to messages

##### Logging shortcuts
- {Cinch::Helpers#debug}
- {Cinch::Helpers#error}
- {Cinch::Helpers#exception}
- {Cinch::Helpers#fatal}
- {Cinch::Helpers#incoming}
- {Cinch::Helpers#info}
- {Cinch::Helpers#log}
- {Cinch::Helpers#outgoing}
- {Cinch::Helpers#warn}

#### {Cinch::IRC}

- {Cinch::IRC#network}

#### {Cinch::Message}

- {Cinch::Message#action?}
- {Cinch::Message#action_message}
- {Cinch::Message#target}
- {Cinch::Message#time}

#### {Cinch::Plugin}

- {Cinch::Plugin#handlers}
- {Cinch::Plugin#timers}
- {Cinch::Plugin#unregister}

#### {Cinch::User}

- {Cinch::User#away}
- {Cinch::User#dcc_send} - See {Cinch::DCC::Outgoing::Send}
- {Cinch::User#match}
- {Cinch::User#monitor} - See {file:docs/common_tasks.md#checking-if-a-user-is-online Checking if a user is online}
- {Cinch::User#monitored}
- {Cinch::User#online?}
- {Cinch::User#unmonitor}

### Handlers

Internally, Cinch uses {Cinch::Handler Handlers} for listening to and
matching events. In previous versions, this was hidden from the user,
but now they're part of the public API, providing valuable information
and the chance to {Cinch::Handler#unregister unregister handlers}
alltogether.

{Cinch::Bot#on} now returns the created handler and
{Cinch::Plugin#handlers} allows getting a plugin's registered
handlers.

### Removed/Renamed methods
The following methods have been removed:

| Removed method                         | Replacement                                                                     |
|----------------------------------------+---------------------------------------------------------------------------------|
| Cinch::Bot#halt                        | `next` or `break` (Ruby keywords)                                               |
| Cinch::Bot#raw                         | {Cinch::IRC#send}                                                               |
| Cinch::Bot#msg                         | {Cinch::Target#msg}                                                             |
| Cinch::Bot#notice                      | {Cinch::Target#notice}                                                          |
| Cinch::Bot#safe_msg                    | {Cinch::Target#safe_msg}                                                        |
| Cinch::Bot#safe_notice                 | {Cinch::Target#safe_notice}                                                     |
| Cinch::Bot#action                      | {Cinch::Target#action}                                                          |
| Cinch::Bot#safe_action                 | {Cinch::Target#safe_action}                                                     |
| Cinch::Bot#dispatch                    | {Cinch::HandlerList#dispatch}                                                   |
| Cinch::Bot#register_plugins            | {Cinch::PluginList#register_plugins}                                            |
| Cinch::Bot#register_plugin             | {Cinch::PluginList#register_plugin}                                             |
| Cinch::Bot#logger                      | {Cinch::Bot#loggers}                                                            |
| Cinch::Bot#logger=                     |                                                                                 |
| Cinch::Bot#debug                       | {Cinch::LoggerList#debug}                                                       |
| Cinch::IRC#message                     | {Cinch::IRC#send}                                                               |
| Cinch::Logger::Logger#log_exception    | {Cinch::Logger#exception}                                                       |
| Class methods in Plugin to set options | A new {Cinch::Plugin::ClassMethods#set set} method as well as attribute setters |


### The Plugin class

The {Cinch::Plugin Plugin} class has been drastically improved to look
and behave more like a proper Ruby class instead of being some
abstract black box.

All attributes of a plugin (name, help message, matchers, …) are being
made available via attribute getters and setters. Furthermore, it is
possible to access a Plugin instance's registered handlers and timers,
as well as unregister plugins.

For a complete overview of available attributes and methods, see
{Cinch::Plugin} and {Cinch::Plugin::ClassMethods}.

### Plugin options

The aforementioned changes also affect the way plugin options are
being set: Plugin options aren't set with DSL-like methods anymore but
instead are made available via {Cinch::Plugin::ClassMethods#set a
`set` method} or alternatively plain attribute setters.

See
{file:docs/migrating.md#plugin-options the migration guide} for more
information.

### Channel/Target/User implement Comparable

{Cinch::Target} and thus {Cinch::Channel} and {Cinch::User} now
implement the Comparable interface, which makes them sortable by all
usual Ruby means.

### Renamed `*Manager` to `*List`

`Cinch::ChannelManager` and `Cinch::UserManager` have been renamed to
{Cinch::ChannelList} and {Cinch::UserList} respectively.

## Added support for broken IRC networks
Special support for the following flawed IRC networks has been added:

- JustinTV
- NGameTV
- IRCnet

## Dynamic timers

It is now possible to create new timers from any method/handler. It is
also possible to {Cinch::Timer#stop stop existing timers} or
{Cinch::Timer#start restart them}.

The easiest way of creating new timers is by using the
{Cinch::Helpers#Timer Timer helper method}, even though it is also
possible, albeit more complex, to create instances of {Cinch::Timer}
directly.

Example:

    match /remind me in (\d+) seconds/
    def execute(m, seconds)
      Timer(seconds.to_i, shots: 1) do
        m.reply "This is your reminder.", true
      end
    end

For more information on timers, see the {Cinch::Timer Timer documentation}.

## New options

- :{file:docs/bot_options.md#dccownip dcc.own_ip}
- :{file:docs/bot_options.md#modes modes}
- :{file:docs/bot_options.md#maxreconnectdelay max_reconnect_delay}
- :{file:docs/bot_options.md#localhost local_host}
- :{file:docs/bot_options.md#delayjoins delay_joins}
- :{file:docs/bot_options.md#saslusername sasl.username}
- :{file:docs/bot_options.md#saslpassword sasl.password}

## New events
- :{file:docs/events.md#action action}
- :{file:docs/events.md#away away}
- :{file:docs/events.md#unaway unaway}
- :{file:docs/events.md#dccsend dcc_send}
- :{file:docs/events.md#owner owner}
- :{file:docs/events.md#dehalfop-deop-deowner-devoice deowner}
- :{file:docs/events.md#leaving leaving}
- :{file:docs/events.md#online online}
- :{file:docs/events.md#offline offline}


# What has changed in 1.1?
1. **New events**
2. **New methods**
3. **New options**
4. **Improved logger**
x. **Deprecated methods**

## New events

- :{file:docs/events.md#op op}
- :{file:docs/events.md#dehalfop-deop-deowner-devoice deop}
- :{file:docs/events.md#voice voice}
- :{file:docs/events.md#dehalfop-deop-deowner-devoice devoice}
- :{file:docs/events.md#halfop halfop}
- :{file:docs/events.md#dehalfop-deop-deowner-devoice dehalfop}
- :{file:docs/events.md#ban ban}
- :{file:docs/events.md#unban unban}
- :{file:docs/events.md#modechange mode_change}
- :{file:docs/events.md#catchall catchall}

Additionally, plugins are now able to send their own events by using
Cinch::Bot#dispatch.

## New methods

### {Cinch::User#last_nick}
Stores the last nick of a user. This can for example be used in `on
:nick` to compare a user's old nick against the new one.

### Cinch::User#notice, Cinch::Channel#notice and Cinch::Bot#notice
For sending notices.

### {Cinch::Message#to_s}
Provides a nicer representation of {Cinch::Message} objects.

### {Cinch::Channel#has_user?}
Provides an easier way of checking if a given user is in a channel

## New options
- {file:docs/bot_options.md#pluginssuffix plugins.suffix}
- {file:docs/bot_options.md#ssluse ssl.use}
- {file:docs/bot_options.md#sslverify ssl.verify}
- {file:docs/bot_options.md#sslcapath ssl.ca_path}
- {file:docs/bot_options.md#sslclientcert ssl.client_cert}
- {file:docs/bot_options.md#nicks nicks}
- {file:docs/bot_options.md#timeoutsread timeouts.read}
- {file:docs/bot_options.md#timeoutsconnect timeouts.connect}
- {file:docs/bot_options.md#pinginterval ping_interval}
- {file:docs/bot_options.md#reconnect reconnect}



## Improved logger
The {Cinch::Logger::FormattedLogger formatted logger} (which is the
default one) now contains timestamps. Furthermore, it won't emit color
codes if not writing to a TTY.

Additionally, it can now log any kind of object, not only strings.

## Deprecated methods

| Deprecated method           | Replacement                        |
|-----------------------------+------------------------------------|
| Cinch::User.find_ensured    | Cinch::UserManager#find_ensured    |
| Cinch::User.find            | Cinch::UserManager#find            |
| Cinch::User.all             | Cinch::UserManager#each            |
| Cinch::Channel.find_ensured | Cinch::ChannelManager#find_ensured |
| Cinch::Channel.find         | Cinch::ChannelManager#find         |
| Cinch::Channel.all          | Cinch::ChannelManager#each         |
