# @title Common Tasks
# @markup kramdown

# Checking if a user is online

Cinch by itself tries to keep track of the online state of users.
Whenever it sees someone speak, change their nick or be in a channel the
bot is also in, it'll set the user to being online. And when a user
quits, gets killed or cannot be whoised/contacted, its state will be
set to offline.

A problem with that information is that it can quickly become out of
sync. Consider the following example:

The bot joins a channel, sees someone in the name list and thus marks
him as online. The bot then leaves the channel and at some later
point, the user disconnects. The bot won't know that and still track
the user as online.

If (near-)realtime information about this state is required, one can
use {Cinch::User#monitor} to automatically monitor the state.
{Cinch::User#monitor #monitor} uses either the _MONITOR_ feature of modern IRCds or, if
that's not available, periodically runs _WHOIS_ to update the
information.

Whenever a user's state changes, either the `:online` or the
`:offline` event will be fired, as can be seen in the following
example:

    class SomePlugin
      include Cinch::Plugin

      listen_to :connect, method: :on_connect
      listen_to :online,  method: :on_online
      listen_to :offline, method: :on_offline

      def on_connect(m)
        User("my_master").monitor
      end

      def on_online(m, user)
        user.send "Hello master"
      end

      def on_offline(m, user)
        @bot.loggers.info "I miss my master :("
      end
    end

# Sending messages to users and channels beside `m.user` and `m.channel`

Cinch provides {Cinch::Helpers helper methods} to get instances of Channel
and User objects that you can work with:

    User('user').send("Hello!")        # Sends a message to user 'user'
    Channel('#channel').send("Hello!") # Sends a message to channel '#channel'

