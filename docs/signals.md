# @title Signals

Cinch provides three kinds of signals:

1. Signals mapping directly to IRC commands

   For example `:topic`, which will be triggered when someone changes
   the topic, or `:kick`, when someone gets kicked.

2. Signals mapping directly to IRC numeric codes

   For example `:"401"` for `ERR_NOSUCHNICK`, which is triggered when
   trying to operate on an unknown nickname, or `:"318"` for
   `RPL_ENDOFWHOIS`, which is triggered after whois information have
   been received.

3. Signals mapping to more abstract ideas

   For example `:leaving` whenever a user parts, quits or gets
   kicked/killed or `:message`, which is actually a synonym for
   `:privmsg`, the underlying IRC command.

# Signals of the first two kinds

All signals of the first two kinds behave exactly the same: When they
get triggered, the handler will be passed a single object, a reference
to the {Cinch::Message Message object}.

Example:

    on :topic do |m|
      # m is the message object
    end

We will not further describe all possible signals of the first two
categories.

# Signals of the third kind

Signals of the third kind can each have different signatures, as they
get passed objects directly relating to their kind, for example the
leaving user in case of `:leaving`. This document will describe all
signals of that kind, their signature and example usage.

**Note: Because *all* handlers receive a {Cinch::Message Message}
  object as the first argument, we will only mention and describe
  additional arguments.**

## `:action`

The `:action` signal is triggered when a user sends a CTCP ACTION to a
channel or the bot. CTCP ACTION is commonly refered to simply as
"actions" or "/me's", because that is the command used in most IRC
clients.

Example:

    on :action, "kicks the bot" do |m|
      m.reply "Ouch! Stop kicking me :(", true
    end


## `:away`

The `:away` signal is triggered when a user goes away. This feature
only works on networks implementing the "away-notify" extension.

Example:

    on :away do |m|
      debug("User %s just went away: %s" % [m.user, m.message])
    end

See also {file:signals.md#unaway the `:unaway` signal}.


## `:ban`

The `:ban` signal is triggered when a user gets banned in a channel.

One additional argument, a {Cinch::Ban Ban object}, gets passed to
the handler.

Example:

    on :ban do |m, ban|
      debug("%s just banned %s" % [ban.by, ban.mask])
    end

See also {file:signals.md#unban the `:unban` signal}.


## `:catchall`

`:catchall` is a special signal that gets triggered for every incoming
IRC message/command, no matter what the type is.


## `:channel`

The `:channel` signal is triggered for channel messages (the usual
form of communication on IRC).

See also {file:signals.md#private the `:private` signal}.


## `:connect`

The `:connect` signal is triggered after the bot successfully
connected to the IRC server.

One common use case for this signal is setting up variables,
synchronising information etc.


## `:ctcp`

The `:ctcp` signal is triggered when receiving CTCP-related messages,
for example the VERSION request.


## `:dcc_send`

`:dcc_send` gets triggered when a user tries to send a file to the
bot, using the DCC SEND protocol.

One additional argument, a {Cinch::DCC::Incoming::Send DCC::Send
object}, gets passed to the handler.

For example usage and a general explanation of DCC in Cinch check
{Cinch::DCC::Incoming::Send}.


## `:dehalfop`, `:deop`, `:deowner`, `:devoice`

These signals get triggered for the respective channel operations of
taking halfop, op, owner and voice from a user.

One additional argument, the user whose rights are being modifed, gets
passed to the handler.


## `:error`

`:error` gets triggered for all numeric replies that signify errors
(`ERR_*`).


## `:halfop`

This signal gets triggered when a user in a channel gets half-opped.

One additional argument, the user being half-opped, gets passed to the
handler.


## `:leaving`

`:leaving` is an signal that is triggered whenever any of the following
are triggered as well: `:part`, `:quit`, `:kick`, `:kill`.

The signal can thus be used for noticing when a user leaves a channel
or the network, no matter the reason.

One additional argument, the leaving user, gets passed to the handler.

Be careful not to confuse the additional argument with
{Cinch::Message#user}. For example in the case of a kick,
{Cinch::Message#user} will describe the user kicking someone, not the
one who is being kicked.

Example:

    on :leaving do |m, user|
      if m.channel?
        debug("%s just left %s." % [user, m.channel])
      else
        debug("%s just left the network." % user)
      end
    end



## `:mode_change`

This signal gets triggered whenever modes in a channel or on the bot
directly change. Unlike signals like `:op`, this signal is more
low-level, as the argument the handler gets passed is an array
describing every change.


## `:offline`

This signal is triggered when a
{file:common_tasks.md#checking-if-a-user-is-online monitored user}
goes offline.

One additional argument, the user going offline, gets passed to the
handler.


## `:online`

This signal is triggered when a
{file:common_tasks.md#checking-if-a-user-is-online monitored user}
comes online.

One additional argument, the user coming online, gets passed to the
handler.


## `:op`

This signal gets triggered when a user in a channel gets opped.

One additional argument, the user being opped, gets passed to the
handler.


## `:owner`


This signal gets triggered when a user in a channel receives
owner-status.

One additional argument, the user receiving owner-status, gets passed
to the handler.


## `:message`

The `:message` signal is triggered for messages directed at either a
channel or directly at the bot. It's synonymous with `:privmsg`.


## `:private`

The `:private` signal is triggered for messages directly towarded at
the bot (think /query in traditional IRC clients).

See also {file:signals.md#channel the `:channel` signal}.


## `:unaway`

The `:unaway` signal is triggered when a user no longer is away. This
feature only works on networks implementing the "away-notify"
extension.

Example:

    on :unaway do |m|
      debug("User %s no longer is away." % m.user)
    end

See also {file:signals.md#away the `:away` signal}.


## `:unban`

The `:unban` signal is triggered when a user gets unbanned in a
channel.

One additional argument, a {Cinch::Ban Ban object}, gets passed to the
handler.


## `:voice`
This signal gets triggered when a user in a channel gets voiced.

One additional argument, the user being voiced, gets passed to the
handler.
