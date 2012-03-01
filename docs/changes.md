# @title What has changed?

<!-- **** DONE Provide an API for acessing plugin infos (name, help, etc) :feature: -->
<!-- **** DONE Introduce a PluginManager                                :refactor: -->
<!-- *** DONE Only return booleans from foo? methods                 :improvement: -->
<!-- *** DONE Load the configuration from a hash                         :feature: -->
<!-- *** DONE Helpers should get defined on the specific Callback, not all.  :bug: -->
<!-- *** DONE Allow unregistering handlers                               :feature: -->
<!-- *** DONE Add a HandlerList class, move Bot#find to it, possibly others  :refactor: -->
<!-- *** DONE provide a class representing timers                    :improvement: -->
<!-- *** DONE rename *Manager classes to *List classes                  :refactor: -->
<!-- *** DONE Subclass Queue instead of monkeypatching it            :improvement: -->
<!-- *** DONE add User#match (alias to User#=~) which calls Mask#match with self :feature: -->
<!-- *** DONE Allow creating new timers dynamically                      :feature: -->
<!-- *** DONE One-shot option for timer                              :improvement: -->
<!-- *** DONE In Bot#generate_next_nick, also set the new nick as the bot's nick :bug: -->
<!-- *** DONE Investigate if Cinch forgets modes for people who change their nicks :bug: -->

# What has changed in 2.x?
1. **Added support for SASL** (2.0.0)
1. **Added support for DCC SEND** (2.0.0)
1. **Added a fair scheduler for outgoing messages** (2.0.0)
1. **Added required plugin options** (2.0.0)
1. **Added support for actions (/me)** (2.0.0)

1. **API improvements** (2.0.0)
   1. **Helper changes** (2.0.0)
   1. **Added a {Cinch::Target Target} class** (2.0.0)
   1. **New methods**
      1. **New {Cinch::Channel} methods** (2.0.0)
      1. **New {Cinch::Message} methods** (2.0.0)
      1. **New {Cinch::Helpers} methods** (2.0.0)
   1. **Removed methods** (2.0.0)


1. **Added support for broken IRC networks** (2.0.0)
1. **Fixed crash when network is down** (2.0.0)
1. **Print warnings when plugins are missing methods** (2.0.0)
1. **New signals** (2.0.0)
1. Channel/User Sortable now

## Added support for SASL (2.0.0)
Cinch now supports authenticating to services via SASL. For more
information check the {file:sasl.md readme on SASL}.

## Added support for DCC SEND (2.0.0)

Support for sending and receiving files via DCC has been added to
Cinch. Check the {file:dcc.md readme on DCC} for more information.

## Added a fair scheduler for outgoing messages (2.0.0)
Cinch always provided sophisticated throttling to avoid getting kicked
due to _excess flood_. One major flaw, however, was that it used a
single FIFO for all messages, thus preferring early message targets
and penalizing later ones.

Now Cinch uses a round-robin approach, having one queue per message
target (channels and users) and one for generic commands.

## Added required plugin options (2.0.0)
Plugins can now require specific options to be set. If any of those
options is not set, the plugin will automatically refuse being loaded.

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

## Added support for actions (/me) (2.0.0)
TODO

## API improvements (2.0.0)

### Helper changes (2.0.0)

The helper methods {Cinch::Helpers#User User()} and
{Cinch::Helpers#Channel Channel()} have been extracted from
{Cinch::Bot} and moved to {Cinch::Helpers their own module} which can
be reused in various places.

### Added a {Cinch::Target Target} class (2.0.0)

Since {Cinch::Channel} and {Cinch::User} share one common interface
for sending messages, it only makes sense to have a common base class.
{Cinch::Target This new class} takes care of sending messages and
removes this responsibility from {Cinch::Channel}, {Cinch::User} and
{Cinch::Bot}


### New methods

#### {Cinch::Channel} (2.0.0)

New methods for getting lists of users:

- {Cinch::Channel#ops}
- {Cinch::Channel#half_ops}
- {Cinch::Channel#admins}
- {Cinch::Channel#voiced}

#### {Cinch::Message} (2.0.0)

New action (/me)-related methods:

- {Cinch::Message#action?}
- {Cinch::Message#action_message}

#### {Cinch::Helpers}

- {Cinch::Helpers#User}
- {Cinch::Helpers#Channel}
- {Cinch::Helpers#Target} -- For creating a {Cinch::Target Target} which can receive messages
- {Cinch::Helpers#Timer}  -- For creating new timers anywhere
- {Cinch::Helpers#rescue_exception} -- For rescueing and automatically logging an exception

### Removed methods (2.0.0)
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
| Cinch::Logger::Logger#log_exception    | {Cinch::Logger#exception}                                               |
| Class methods in Plugin to set options | A new {Cinch::Plugin::ClassMethods#set set} method as well as attribute setters |


## Added support for broken IRC networks (2.0.0)
Special support for the following flawed IRC networks has been added:

- JustinTV
- NGameTV
- IRCnet

## Fixed crash when network is down (2.0.0)

Cinch will no longer crash when trying to connect to a server while
the local network is down.

## Print warnings when plugins are missing methods (2.0.0)
TODO

## New signals (2.0.0)
TODO
:action
:online
:offline


# What has changed in 1.1.x?
1. **New signals** (1.1.0)
2. **New methods** (1.1.0)
3. **New options** (1.1.0)
4. **Improved logger** (1.1.0)
x. **Deprecated methods** (1.1.0)

## New signals (1.1.0)

| Name/Signature                                                                       | Description                                     |
|--------------------------------------------------------------------------------------+-------------------------------------------------|
| :op(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::User User}&gt;target)       | emitted when someone gets opped                 |
| :deop(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::User User}&gt;target)     | emitted when someone gets deopped               |
| :voice(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::User User}&gt;target)    | emitted when someone gets voiced                |
| :devoice(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::User User}&gt;target)  | emitted when someone gets devoiced              |
| :halfop(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::User User}&gt;target)   | emitted when someone gets half-opped            |
| :dehalfop(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::User User}&gt;target) | emitted when someone gets de-half-opped         |
| :ban(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::Ban Ban}&gt;ban)           | emitted when someone gets banned                |
| :unban(&lt;{Cinch::Message Message}&gt;message, &lt;{Cinch::Ban Ban}&gt;ban)         | emitted when someone gets unbanned              |
| :mode_change(&lt;{Cinch::Message Message}&gt;message, &lt;Array&gt;modes)            | emitted on any mode change on a user or channel |
| :catchall(&lt;{Cinch::Message Message}&gt;message)                                   | a generic signal that matches any kind of event |

Additionally, plugins are now able to send their own events by using
Cinch::Bot#dispatch.

## New methods (1.1.0)

### {Cinch::User#last_nick}
Stores the last nick of a user. This can for example be used in `on
:nick` to compare a user's old nick against the new one.

### Cinch::User#notice, Cinch::Channel#notice and Cinch::Bot#notice
For sending notices.

### {Cinch::Message#to_s}
Provides a nicer representation of {Cinch::Message} objects.

### {Cinch::Channel#has_user?}
Provides an easier way of checking if a given user is in a channel

## New options (1.1.0)
- plugins.suffix
- ssl.use
- ssl.verify
- ssl.ca_path
- ssl.client_cert
- nicks
- timeouts.read
- timeouts.connect
- ping_interval
- reconnect



## Improved logger (1.1.0)
The {Cinch::Logger::FormattedLogger formatted logger} (which is the
default one) now contains timestamps. Furthermore, it won't emit color
codes if not writing to a TTY.

Additionally, it can now log any kind of object, not only strings.

## Deprecated methods (1.1.0)

| Deprecated method           | Replacement                        |
|-----------------------------+------------------------------------|
| Cinch::User.find_ensured    | Cinch::UserManager#find_ensured    |
| Cinch::User.find            | Cinch::UserManager#find            |
| Cinch::User.all             | Cinch::UserManager#each            |
| Cinch::Channel.find_ensured | Cinch::ChannelManager#find_ensured |
| Cinch::Channel.find         | Cinch::ChannelManager#find         |
| Cinch::Channel.all          | Cinch::ChannelManager#each         |
