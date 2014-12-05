# @title Bot options
# @markup kramdown

# Options

## channels
Type
: Array<String>

Default value
: `[]`

Description
: Channels in this list will be joined upon connecting.


### Notes
- To automatically join password-protected channels, just append the
  password to the channel's name, separated by a space, e.g.
  `"#mychannel mypassword"`.

## dcc

### dcc.own_ip
Type
: String

Default value
: `nil`

Description
: The external IP which should be used for outgoing DCC SENDs. For
more information see {Cinch::DCC::Outgoing::Send}.

## delay_joins
Type
: Number, Symbol

Default value
: `0`

Description
: Delay joining channels N seconds after connecting, or until the event S fires.

### Notes
- This is especially useful in combination with the /cinch-identify/ plugin, which will trigger the `:identified` event.

## encoding
Type
: String, Encoding

Default value
: `:irc`

Description
: This determines which encoding text received from IRC will have.


### Notes
- {file:docs/encodings.md More information on how Cinch handles encoding issues}

## local_host
Type
: String

Default value
: `nil`

Description
: Which IP/host to bind to when connecting. This is useful for using
  so called "vhosts".

## max_messages
Type
: Fixnum

Default value
: `nil`

Description
: When an overlong message gets split, only `max_messages` parts will
  be sent to the recipient.


### Notes
- Set this option to `nil` to disable any limit.

## max_reconnect_delay
Type
: Fixnum

Default value
: `300`

Descriptipn
: With every unsuccessful reconnection attempt, Cinch increases the
  delay between new attempts. This setting is the maximum number of
  seconds to wait between two attempts.

## messages_per_second
Type
: Float

Default value
: Network dependent

Description
: How many incoming messages the server processes per second. This is
  used for throttling.


### Notes
- If your bot gets kicked for excess flood, try lowering the value of
  `messages_per_second`.
- See also: {file:docs/bot_options.md#serverqueuesize `server_queue_size`}

## message_split_end
Type
: String

Default value
: `" ..."`

Description
: When a message is too long to be sent as a whole, it will be split
  and the value of this option will be appended to all but the last
  parts of the message.


## message_split_start
Type
: String

Default value
: `"... "`

Description
: When a message is too long to be sent as a whole, it will be split
  and the value of this option will be prepended to all but the first
  parts of the message.

## modes
Type
: Array<String>

Default value
: []

Description
: An array of modes the bot should set on itself after connecting.

## nick
Type
: String

Default value
: `"cinch"`

Description
: The nickname the bot will use.


### Notes
- If the nickname is in use, Cinch will append underscores until it
  finds a free nick.
- You really should set this option instead of using the default.

## nicks
Type
: Array<String>

Default value
: `nil`

Description
: This option overrules {file:docs/bot_options.md#nick `nick`} and allows Cinch
  to try multiple nicks before adding underscores.


## password
Type
: String

Default value
: `nil`

Description
: A server password for access to private servers.


### Notes
- Some networks allow you to use the server password for
  authenticating with services (e.g. NickServ).


## ping_interval
Type
: Number

Default value
: `120`

Description
: The server will be pinged every X seconds, to keep the connection
  alive.


### Notes
- The ping interval should be smaller than
  {file:docs/bot_options.md#timeoutsread `timeouts.read`} to prevent Cinch from
  falsely declaring a connection dead.


## plugins

### plugins.plugins
Type
: Array<Class>

Default value
: `[]`

Description
: A list of plugins to register.


#### Notes
- An example: `[Plugin1, Plugin2, Plugin3]` -- Note that we are adding
  the plugin **classes** to the list.

### plugins.prefix
Type
: String, Regexp, Lambda

Default value
: `/^!/`

Description
: A prefix that will be prepended to all plugin commands.


### plugins.suffix
Type
: String, Regexp, Lambda

Default value
: `nil`

Description
: A suffix that will be appended to all plugin commands.



### plugins.options
Type
: Hash

Default value
: `Hash.new {|h,k| h[k] = {}}`

Description
: Options specific to plugins.


#### Notes
- Information on plugins and options for those will be made available
  in a separate document soon.


## port
Type
: Fixnum

Default value
: `6667`

Description
: The port the IRC server is listening on


## realname
Type
: String

Default value
: `"cinch"`

Description
: The real name Cinch will connect with.

## reconnect
Type
: Boolean

Default value
: `true`

Description
: Should Cinch attempt to reconnect after a connection loss?

## sasl

### sasl.username
Type
: String

Default value
: `nil`

Description
: The username to use for SASL authentication.

### sasl.password
Type
: String

Default value
: `nil`

Description
: The password to use for SASL authentication.

## server
Type
: String

Default value
: `"localhost"`

Description
: The IRC server to connect to


## server_queue_size
Type
: Fixnum

Default value
: Network dependent

Description
: The number of incoming messages the server will queue, before
  killing the bot for excess flood.


### Notes
- If your bot gets kicked for excess flood, try lowering the value of
  `server_queue_size`.
- See also: {file:docs/bot_options.md#messagespersecond `messages_per_second`}

## ssl

### ssl.use
Type
: Boolean

Default value
: `false`

Description
: Sets if SSL should be used

### ssl.verify
Type
: Boolean

Default value
: `false`

Description
: Sets if the SSL certificate should be verified


### ssl.ca_path
Type
: String

Default value
: `"/etc/ssl/certs"`

Description
: The path to a directory with certificates. This has to be set
  properly for {file:docs/bot_options.md#sslverify `ssl.verify`} to work.


### ssl.client_cert
Type
: String

Default value
: `nil`

Description
: The path to a client certificate, which some networks can use for
  authentication (see {http://www.oftc.net/oftc/NickServ/CertFP})


#### Notes
- You will want to set the correct port when using SSL

## user
Type
: String

Default value
: `"cinch"`

Description
: The user name to use when connecting to the IRC server.

## timeouts

### timeouts.read
Type
: Number

Default value
: `240`

Description
: If no data has been received for this amount of seconds, the
  connection will be considered dead.


### timeouts.connect
Type
: Number

Default value
: `10`

Description
: Give up connecting after this amount of seconds.

