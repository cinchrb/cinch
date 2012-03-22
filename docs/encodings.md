# @title Encodings
# @markup kramdown

# Encodings

The IRC protocol doesn't define a specific encoding that should be
used, nor does it provide any information on which encodings _are_
being used.

At the same time, lots of different encodings have become popular on
IRC. This presents a big problem, because, if you're using a different
encoding than someone else on IRC, you'll receive their text as
garbage.

Cinch tries to work around this issue in two ways, while also keeping
the usual Ruby behaviour.

## The `encoding` option
By setting {file:docs/bot_options.md#encoding the `encoding` option}, you
set your expectations on what encoding other users will use. Allowed
values are instances of Encoding, names of valid encodings (as
strings) and the special `:irc` encoding, which will be explained
further down.


## Encoding.default_internal
If set, Cinch will automatically convert incoming messages to the
encoding defined by `Encoding.default_internal`, unless the special
encoding `:irc` is being used as the {file:docs/bot_options.md#encoding
`encoding option`}

## The `:irc` encoding
As mentioned earlier, people couldn't decide on a single encoding to
use. As such, specifying a single encoding would most likely lead to
problems, especially if the bot is in more than one channel.

Luckily, even though people cannot decide on a single encoding,
western countries usually either use CP1252 (Windows Latin-1) or
UTF-8. Since text encoded in CP1252 fails validation as UTF-8, it is
easy to tell the two apart. Additionally it is possible to losslessly
re-encode CP1252 in UTF-8 and as such, a small subset of UTF-8 is also
representable in CP1252.

If incoming text is valid UTF-8, it will be interpreted as such. If it
fails validation, a CP1252 → UTF-8 conversion is performed. This
ensures that you will always deal with UTF-8 in your code, even if
other people use CP1252. Note, however, that we ignore
`Encoding.default_internal` in this case and always present you with
UTF-8.

If text you send contains only characters that fit inside the
CP1252 code page, the entire line will be sent that way.

If the text doesn't fit inside the CP1252 code page, (for example if
you type Eastern European characters, or Russian) it will be sent as
UTF-8. Only UTF-8 capable clients will be able to see these characters
correctly.

## Invalid bytes and unsupported translations
If Cinch receives text in an encoding other than the one assumed, it
can happen that the message contains bytes that are not valid in the
assumed encoding. Instead of dropping the complete message, Cinch will
replace offending bytes with question marks.

Also, if you expect messages in e.g. UTF-8 but re-encode them in
CP1252 (by setting `Encoding.default_internal` to CP1252), it can
happen that some characters cannot be represented in CP1252. In such a
case, Cinch will too replace the offending characters with question
marks.
