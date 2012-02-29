module Cinch
  # All standard and some non-standard numeric replies used by the IRC
  # protocol.
  module Constants
    # Used to indicate the nickname parameter supplied to a command is
    # currently unused.
    ERR_NOSUCHNICK = 401

    # Used to indicate the server name given currently doesn't exist.
    ERR_NOSUCHSERVER = 402

    # Used to indicate the given channel name is invalid.
    ERR_NOSUCHCHANNEL = 403

    # Sent to a user who is either
    #  - not on a channel which is mode +n
    #  - not a chanop (or mode +v) on a channel which has mode +m set
    #    and is trying to send a PRIVMSG message to that channel.
    ERR_CANNOTSENDTOCHAN = 404

    # Sent to a user when they have joined the maximum number of allowed
    # channels and they try to join another channel.
    ERR_TOOMANYCHANNELS = 405

    # Returned by WHOWAS to indicate there is no history information for
    # that nickname.
    ERR_WASNOSUCHNICK = 406

    # Returned to a client which is attempting to send PRIVMSG/NOTICE
    # using the user@host destination format and for a user@host which has
    # several occurrences.
    ERR_TOOMANYTARGETS = 407

    # PING or PONG message missing the originator parameter which is
    # required since these commands must work without valid prefixes.
    ERR_NOORIGIN     = 409

    # @todo Document this constant
    ERR_NORECIPIENT  = 411

    # @todo Document this constant
    ERR_NOTEXTTOSEND = 412

    # @todo Document this constant
    ERR_NOTOPLEVEL   = 413

    # 412 - 414 are returned by PRIVMSG to indicate that the message
    # wasn't delivered for some reason. ERR_NOTOPLEVEL and
    # ERR_WILDTOPLEVEL are errors that are returned when an invalid use of
    # "PRIVMSG $&lt;server&gt;" or "PRIVMSG #&lt;host&gt;" is attempted.
    ERR_WILDTOPLEVEL = 414

    # Returned to a registered client to indicate that the command sent is
    # unknown by the server.
    ERR_UNKNOWNCOMMAND = 421

    # Server's MOTD file could not be opened by the server.
    ERR_NOMOTD = 422

    # Returned by a server in response to an ADMIN message when there is
    # an error in finding the appropriate information.
    ERR_NOADMININFO = 423

    # Generic error message used to report a failed file operation during
    # the processing of a message.
    ERR_FILEERROR = 424

    # Returned when a nickname parameter expected for a command and isn't
    # found.
    ERR_NONICKNAMEGIVEN = 431

    # Returned after receiving a NICK message which contains characters
    # which do not fall in the defined set.
    ERR_ERRONEUSNICKNAME = 432

    # Returned when a NICK message is processed that results in an attempt
    # to change to a currently existing nickname.
    ERR_NICKNAMEINUSE = 433

    # Returned by a server to a client when it detects a nickname
    # collision (registered of a NICK that already exists by another
    # server).
    ERR_NICKCOLLISION = 436

    # Returned by the server to indicate that the target user of the
    # command is not on the given channel.
    ERR_USERNOTINCHANNEL = 441

    # Returned by the server whenever a client tries to perform a channel
    # effecting command for which the client isn't a member.
    ERR_NOTONCHANNEL = 442

    # Returned when a client tries to invite a user to a channel they are
    # already on.
    ERR_USERONCHANNEL = 443

    # Returned by the summon after a SUMMON command for a user was unable
    # to be performed since they were not logged in.
    ERR_NOLOGIN = 444

    # Returned as a response to the SUMMON command. Must be returned by
    # any server which does not implement it.
    ERR_SUMMONDISABLED = 445

    # Returned as a response to the USERS command. Must be returned by any
    # server which does not implement it.
    ERR_USERSDISABLED = 446

    # Returned by the server to indicate that the client must be
    # registered before the server will allow it to be parsed in detail.
    ERR_NOTREGISTERED = 451

    # Returned by the server by numerous commands to indicate to the
    # client that it didn't supply enough parameters.
    ERR_NEEDMOREPARAMS = 461

    # Returned by the server to any link which tries to change part of the
    # registered details (such as password or user details from second
    # USER message).
    ERR_ALREADYREGISTRED = 462

    # Returned to a client which attempts to register with a server which
    # does not been setup to allow connections from the host the attempted
    # connection is tried.
    ERR_NOPERMFORHOST = 463

    # Returned to indicate a failed attempt at registering a connection
    # for which a password was required and was either not given or
    # incorrect.
    ERR_PASSWDMISMATCH = 464

    # Returned after an attempt to connect and register yourself with a
    # server which has been setup to explicitly deny connections to you.
    ERR_YOUREBANNEDCREEP = 465

    # @todo Document this constant
    ERR_KEYSET           = 467

    # @todo Document this constant
    ERR_CHANNELISFULL    = 471

    # @todo Document this constant
    ERR_UNKNOWNMODE      = 472

    # @todo Document this constant
    ERR_INVITEONLYCHAN   = 473

    # @todo Document this constant
    ERR_BANNEDFROMCHAN   = 474

    # @todo Document this constant
    ERR_BADCHANNELKEY    = 475

    # Any command requiring operator privileges to operate must return
    # this error to indicate the attempt was unsuccessful.
    ERR_NOPRIVILEGES = 481

    # Any command requiring 'chanop' privileges (such as MODE messages)
    # must return this error if the client making the attempt is not a
    # chanop on the specified channel.
    ERR_CHANOPRIVSNEEDED = 482

    # Any attempts to use the KILL command on a server are to be refused
    # and this error returned directly to the client.
    ERR_CANTKILLSERVER = 483

    # If a client sends an OPER message and the server has not been
    # configured to allow connections from the client's host as an
    # operator, this error must be returned.
    ERR_NOOPERHOST = 491

    # Returned by the server to indicate that a MODE message was sent with
    # a nickname parameter and that the a mode flag sent was not
    # recognized.
    ERR_UMODEUNKNOWNFLAG = 501

    # Error sent to any user trying to view or change the user mode for a
    # user other than themselves.
    ERR_USERSDONTMATCH = 502

    # @todo Document this constant
    RPL_NONE           = 300

    # Reply format used by USERHOST to list replies to the query list.
    RPL_USERHOST = 302

    # Reply format used by ISON to list replies to the query list.
    RPL_ISON = 303

    # RPL_AWAY is sent to any client sending a PRIVMSG to a client which
    # is away. RPL_AWAY is only sent by the server to which the client is
    # connected.
    RPL_AWAY = 301

    # Replies RPL_UNAWAY and RPL_NOWAWAY are sent when the client removes
    # and sets an AWAY message
    RPL_UNAWAY = 305

    # Replies RPL_UNAWAY and RPL_NOWAWAY are sent when the client removes
    # and sets an AWAY message
    RPL_NOWAWAY       = 306

    # @todo Document this constant
    RPL_WHOISUSER     = 311

    # @todo Document this constant
    RPL_WHOISSERVER   = 312

    # @todo Document this constant
    RPL_WHOISOPERATOR = 313

    # @todo Document this constant
    RPL_WHOISIDLE     = 317

    # @todo Document this constant
    RPL_ENDOFWHOIS    = 318

    # Replies 311 - 313, 317 - 319 are all replies generated in response
    # to a WHOIS message. Given that there are enough parameters present,
    # the answering server must either formulate a reply out of the above
    # numerics (if the query nick is found) or return an error reply. The
    # '*' in RPL_WHOISUSER is there as the literal character and not as a
    # wild card. For each reply set, only RPL_WHOISCHANNELS may appear
    # more than once (for long lists of channel names). The '@' and '+'
    # characters next to the channel name indicate whether a client is a
    # channel operator or has been granted permission to speak on a
    # moderated channel. The RPL_ENDOFWHOIS reply is used to mark the end
    # of processing a WHOIS message.
    RPL_WHOISCHANNELS = 319

    # @todo Document this constant
    RPL_WHOWASUSER    = 314

    # When replying to a WHOWAS message, a server must use the replies
    # RPL_WHOWASUSER, RPL_WHOISSERVER or ERR_WASNOSUCHNICK for each
    # nickname in the presented list. At the end of all reply batches,
    # there must be RPL_ENDOFWHOWAS (even if there was only one reply and
    # it was an error).
    RPL_ENDOFWHOWAS = 369

    # @todo Document this constant
    RPL_LISTSTART   = 321

    # @todo Document this constant
    RPL_LIST        = 322

    # Replies RPL_LISTSTART, RPL_LIST, RPL_LISTEND mark the start, actual
    # replies with data and end of the server's response to a LIST
    # command. If there are no channels available to return, only the
    # start and end reply must be sent.
    RPL_LISTEND       = 323

    # @todo Document this constant
    RPL_CHANNELMODEIS = 324

    # @todo Document this constant
    RPL_NOTOPIC       = 331

    # When sending a TOPIC message to determine the channel topic, one of
    # two replies is sent. If the topic is set, RPL_TOPIC is sent back
    # else RPL_NOTOPIC.
    RPL_TOPIC = 332

    # Returned by the server to indicate that the attempted INVITE message
    # was successful and is being passed onto the end client.
    RPL_INVITING = 341

    # Returned by a server answering a SUMMON message to indicate that it
    # is summoning that user.
    RPL_SUMMONING = 342

    # Reply by the server showing its version details. The &lt;version&gt;
    # is the version of the software being used (including any patchlevel
    # revisions) and the &lt;debuglevel&gt; is used to indicate if the
    # server is running in "debug mode".
    #
    #The "comments" field may contain any comments about the version or
    # further version details.
    RPL_VERSION  = 351

    # @todo Document this constant
    RPL_WHOREPLY = 352

    # The RPL_WHOREPLY and RPL_ENDOFWHO pair are used to answer a WHO
    # message. The RPL_WHOREPLY is only sent if there is an appropriate
    # match to the WHO query. If there is a list of parameters supplied
    # with a WHO message, a RPL_ENDOFWHO must be sent after processing
    # each list item with &lt;name&gt; being the item.
    RPL_ENDOFWHO  = 315

    # @todo Document this constant
    RPL_NAMREPLY  = 353

    # @todo Document this constant
    RPL_NAMEREPLY = RPL_NAMREPLY

    # @todo Document this constant
    RPL_WHOSPCRPL = 354

    # To reply to a NAMES message, a reply pair consisting of RPL_NAMREPLY
    # and RPL_ENDOFNAMES is sent by the server back to the client. If
    # there is no channel found as in the query, then only RPL_ENDOFNAMES
    # is returned. The exception to this is when a NAMES message is sent
    # with no parameters and all visible channels and contents are sent
    # back in a series of RPL_NAMEREPLY messages with a RPL_ENDOFNAMES to
    # mark the end.
    RPL_ENDOFNAMES = 366

    # @todo Document this constant
    RPL_LINKS      = 364

    # In replying to the LINKS message, a server must send replies back
    # using the RPL_LINKS numeric and mark the end of the list using an
    # RPL_ENDOFLINKS reply.
    RPL_ENDOFLINKS = 365

    # @todo Document this constant
    RPL_BANLIST    = 367

    # When listing the active 'bans' for a given channel, a server is
    # required to send the list back using the RPL_BANLIST and
    # RPL_ENDOFBANLIST messages. A separate RPL_BANLIST is sent for each
    # active banid. After the banids have been listed (or if none present)
    # a RPL_ENDOFBANLIST must be sent.
    RPL_ENDOFBANLIST = 368

    # @todo Document this constant
    RPL_INFO         = 371

    # A server responding to an INFO message is required to send all its
    # 'info' in a series of RPL_INFO messages with a RPL_ENDOFINFO reply
    # to indicate the end of the replies.
    RPL_ENDOFINFO = 374

    # @todo Document this constant
    RPL_MOTDSTART = 375

    # @todo Document this constant
    RPL_MOTD      = 372

    # When responding to the MOTD message and the MOTD file is found, the
    # file is displayed line by line, with each line no longer than 80
    # characters, using RPL_MOTD format replies. These should be
    # surrounded by a RPL_MOTDSTART (before the RPL_MOTDs) and an
    # RPL_ENDOFMOTD (after).
    RPL_ENDOFMOTD = 376

    # RPL_YOUREOPER is sent back to a client which has just successfully
    # issued an OPER message and gained operator status.
    RPL_YOUREOPER = 381

    # If the REHASH option is used and an operator sends a REHASH message,
    # an RPL_REHASHING is sent back to the operator.
    RPL_REHASHING = 382

    # @todo Document this constant
    RPL_QLIST      = 386

    # @todo Document this constant
    RPL_ENDOFQLIST = 387

    # When replying to the TIME message, a server must send the reply
    # using the RPL_TIME format above. The string showing the time need
    # only contain the correct day and time there. There is no further
    # requirement for the time string.
    RPL_TIME       = 391

    # @todo Document this constant
    RPL_USERSSTART = 392

    # @todo Document this constant
    RPL_USERS      = 393

    # @todo Document this constant
    RPL_ENDOFUSERS = 394

    # If the USERS message is handled by a server, the replies
    # RPL_USERSTART, RPL_USERS, RPL_ENDOFUSERS and RPL_NOUSERS are used.
    # RPL_USERSSTART must be sent first, following by either a sequence of
    # RPL_USERS or a single RPL_NOUSER. Following this is RPL_ENDOFUSERS.
    RPL_NOUSERS         = 395

    # @todo Document this constant
    RPL_TRACELINK       = 200

    # @todo Document this constant
    RPL_TRACECONNECTING = 201

    # @todo Document this constant
    RPL_TRACEHANDSHAKE  = 202

    # @todo Document this constant
    RPL_TRACEUNKNOWN    = 203

    # @todo Document this constant
    RPL_TRACEOPERATOR   = 204

    # @todo Document this constant
    RPL_TRACEUSER       = 205

    # @todo Document this constant
    RPL_TRACESERVER     = 206

    # @todo Document this constant
    RPL_TRACENEWTYPE    = 208

    # The RPL_TRACE* are all returned by the server in response to the
    # TRACE message. How many are returned is dependent on the the TRACE
    # message and whether it was sent by an operator or not. There is no
    # predefined order for which occurs first. Replies RPL_TRACEUNKNOWN,
    # RPL_TRACECONNECTING and RPL_TRACEHANDSHAKE are all used for
    # connections which have not been fully established and are either
    # unknown, still attempting to connect or in the process of completing
    # the 'server handshake'. RPL_TRACELINK is sent by any server which
    # handles a TRACE message and has to pass it on to another server. The
    # list of RPL_TRACELINKs sent in response to a TRACE command
    # traversing the IRC network should reflect the actual connectivity of
    # the servers themselves along that path. RPL_TRACENEWTYPE is to be
    # used for any connection which does not fit in the other categories
    # but is being displayed anyway.
    RPL_TRACELOG      = 261

    # @todo Document this constant
    RPL_STATSLINKINFO = 211

    # @todo Document this constant
    RPL_STATSCOMMANDS = 212

    # @todo Document this constant
    RPL_STATSCLINE    = 213

    # @todo Document this constant
    RPL_STATSNLINE    = 214

    # @todo Document this constant
    RPL_STATSILINE    = 215

    # @todo Document this constant
    RPL_STATSKLINE    = 216

    # @todo Document this constant
    RPL_STATSYLINE    = 218

    # @todo Document this constant
    RPL_ENDOFSTATS    = 219

    # @todo Document this constant
    RPL_STATSLLINE    = 241

    # @todo Document this constant
    RPL_STATSUPTIME   = 242

    # @todo Document this constant
    RPL_STATSOLINE    = 243

    # @todo Document this constant
    RPL_STATSHLINE    = 244

    # To answer a query about a client's own mode, RPL_UMODEIS is sent
    # back.
    RPL_UMODEIS       = 221

    # @todo Document this constant
    RPL_LUSERCLIENT   = 251

    # @todo Document this constant
    RPL_LUSEROP       = 252

    # @todo Document this constant
    RPL_LUSERUNKNOWN  = 253

    # @todo Document this constant
    RPL_LUSERCHANNELS = 254

    # In processing an LUSERS message, the server sends a set of replies
    # from RPL_LUSERCLIENT, RPL_LUSEROP, RPL_USERUNKNOWN,
    # RPL_LUSERCHANNELS and RPL_LUSERME. When replying, a server must send
    # back RPL_LUSERCLIENT and RPL_LUSERME. The other replies are only
    # sent back if a non-zero count is found for them.
    RPL_LUSERME   = 255

    # @todo Document this constant
    RPL_ADMINME   = 256

    # @todo Document this constant
    RPL_ADMINLOC1 = 257

    # @todo Document this constant
    RPL_ADMINLOC2 = 258

    # When replying to an ADMIN message, a server is expected to use
    # replies RLP_ADMINME through to RPL_ADMINEMAIL and provide a text
    # message with each. For RPL_ADMINLOC1 a description of what city,
    # state and country the server is in is expected, followed by details
    # of the university and department (RPL_ADMINLOC2) and finally the
    # administrative contact for the server (an email address here is
    # required) in RPL_ADMINEMAIL.
    RPL_ADMINEMAIL = 259

    # @todo Document this constant
    RPL_MONONLINE    = 730

    # @todo Document this constant
    RPL_MONOFFLINE   = 731

    # @todo Document this constant
    RPL_MONLIST      = 732

    # @todo Document this constant
    RPL_ENDOFMONLIST = 733

    # @todo Document this constant
    ERR_MONLISTFULL  = 734

    # @todo Document this constant
    RPL_SASLLOGIN = 900

    # @todo Document this constant
    RPL_SASLSUCCESS = 903

    # @todo Document this constant
    RPL_SASLFAILED = 904

    # @todo Document this constant
    RPL_SASLERROR = 905

    # @todo Document this constant
    RPL_SASLABORT = 906

    # @todo Document this constant
    RPL_SASLALREADYAUTH = 907
  end
end
