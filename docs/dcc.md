# @title DCC

# DCC SEND

DCC SEND is a protocol for transferring files, usually found in IRC.
While the handshake, i.e. the details of the file transfer, are
transferred over IRC, the actual file transfer happens directly
between two clients. As such it doesn't put stress on the IRC server.

## Using it in Cinch

Cinch allows for both sending and receiving files as well as other
Ruby objects implementing {Cinch::DCC::DCCableObject a certain
interface}.

### Sending

Sending can be done by using {Cinch::User#dcc_send}, which expects an
object to send as well as optionally a file name, which is sent to the
receiver as a suggestion where to save the file. If no file name is
provided, the method will use the object's `#path` object to determine
it.

The most common usage will be sending files:

    match "send me something"
    def execute(m)
      m.user.dcc_send(open("/tmp/cookies"))
    end

More generally, any object that implements {Cinch::DCC::DCCableObject}
can be sent.

### Receiving

When someone tries to send a file to the bot, the `:dcc_send` signal
will be triggered, in which the DCC request can be inspected and
optionally accepted.

The event handler receives the plain message object as well as an
instance of {Cinch::DCC::Incoming::Send}. That instance contains
information about {Cinch::DCC::Incoming::Send#filename the suggested
file name} (in a sanitized way) and allows for checking the origin.

It is advised to reject transfers that seem to originate from a
{Cinch::DCC::Incoming::Send#from_private_ip? private IP} or
{Cinch::DCC::Incoming::Send#from_localhost? the local IP itself}
unless that is expected. Otherwise, specially crafted requests could
cause the bot to connect to internal services.

Finally, the file transfer can be {Cinch::DCC::Incoming::Send#accept
accepted} and written to any object that implements a `#<<` method,
which includes File objects as well as plain strings.

The following is a short example of accepting a file transfer and
saving it to a temporary file:

    require "tempfile"

    listen_to :dcc_send, method: :incoming_dcc
    def incoming_dcc(m, dcc)
      if dcc.from_private_ip? || dcc.from_localhost?
        @bot.loggers.debug "Not accepting potentially dangerous file transfer"
        return
      end

      t = Tempfile.new(dcc.filename)
      dcc.accept(t)
      t.close
    end

### Configuration

If the bot is connected directly to the internet, no configuration is
necessary. Should it, however, be routed through NAT, it is necessary
to manually set the external IP or otherwise it won't be possible to
send files.

The option for this is called `dcc.own_ip`, which has to be set to a
string representation of the IP.
