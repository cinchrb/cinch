= Cinch: The IRC Bot Building Framework

== Description
Cinch is an IRC Bot Building Framework for quickly creating IRC bots
in Ruby with minimal effort.
It provides a minimal interface based on plugins and rules. It's as simple as creating a
plugin, defining a rule, and watching your profits flourish.

Cinch will do all of the hard work for you, so you can spend time creating cool plugins
and extensions to wow your internet peers.

If you'd like to test your own Cinch experiments you can do so in the cinch IRC channel
on {irc.freenode.org}[irc://irc.freenode.org/cinch]. Support is also welcome here.

== Installation

=== RubyGems
You can install the latest version of Cinch using RubyGems
 gem install cinch

=== GitHub
Alternatively you can check out the latest code directly from Github
 git clone http://github.com/injekt/cinch.git

== Example
Your typical <em>Hello, World</em> application would go something like this:

 require 'cinch'

 bot = Cinch.setup do
   server "irc.freenode.org"
   nick "Cinch"
 end

 bot.plugin "hello" do |m|
   m.reply "Hello, #{m.nick}!"
 end

 bot.run

It doesn't take much to work out what's happening here, but I'll explain it anyway.

First we run the <em>Cinch::setup</em> block which is required in every application. Cinch is boxed
with a load of default values, so the <b>only</b> option required in this block is the server. 

We then define a plugin using the <em>plugin</em> method and pass it a rule (a String in this
case). Every plugin must be mapped to a rule. When the rule matches an IRC message its block is
invoked, the contents of which contains your plugin interface. The variable passed to the block is
an instance of Cinch::IRC::Message.

Cinch::IRC::Message also supplies us with some helper methods which aid in replying to users and 
channels.

=== See Also
* Cinch::IRC::Message#reply
* Cinch::IRC::Message#answer

This example would provide the following response on IRC:

 * Cinch has joined #cinch
 injekt> !hello
 Cinch> Hello, injekt!

Since Cinch doesn't provide a binary executable, running your application is as simple as you would any 
other Ruby script. 

 ruby hello.rb

Cinch also parses the command line for options, to save you having to configure 
options within your script.

 ruby hello.rb -s irc.freenode.org -n Coolbot
 ruby hello.rb -C foo,bar

Doing a <b>ruby hello.rb -h</b> provides all possible command line options. 

When using the <em>-C</em> or <em>--channels</em> option, the channel prefix is 
optional, and if none is given the channel will be prefixed with a hash (#) character.

== Plugins
Plugins are invoked using the command prefix character (which by default is set to <b>!</b>). You can
also tell Cinch to ignore any command prefix and instead use the bots username. This would provide
a result similar to this:

 injekt> Cinch: hello
 Cinch> Hello, injekt!

Cinch also provides named parameters. This method of expression was inspired by the {Sinatra
Web Framework}[http://www.sinatrarb.com/] and although it doesn't quite follow the same pattern,
it's useful for naming parameters passed to plugins. These paramaters are available through the 
Cinch::IRC::Message#args method which is passed to each plugin.

 bot.plugin("say :text") do |m|
   m.reply m.args[:text]
 end

This plugin would provide the following output:

 injekt> !say foo bar baz
 Cinch> foo bar baz

Each plugin takes an optional hash of message specific options. These options provide an extension to
the rules given, for example if we want to reply only if the nick sending the message is injekt, we
could pass the 'nick' option to the hash.

 bot.plugin("join :channel", :nick => 'injekt') do |m|
   bot.join #{m.args[:channel]}
 end

This method also works for arrays, to only reply to a message sent in the foo and bar channels

 bot.plugin :hello, :channel => ['#foo', '#bar'] do |m|
   m.reply "Hello"
 end

You can also set a custom prefix for each individual plugin, this is a great method if you have 
two commands which do slightly different things. You can seperate the commands depending on which
prefix the rule contains. 

 bot.plugin "foo", :prefix => '@' do |m|
   m.reply "Doing foo.."
 end

You can also prefix the rule with the bots nickname. Either pass the <b>:bot</b>, <b>:botnick</b> or
<b>bot.nick</b> values to the prefix option.

 bot.plugin "foo", :prefix => :bot do |m|
   m.reply "Doing foo.."
 end

Assuming the username is cinch, this will respond to the following:
* cinch: foo
* cinch, foo

More examples of this can be found in the /examples directory

== Named Parameter Patterns
Since version 0.2, Cinch supports named parameter patterns. It means stuff like the this works:

 bot.plugin("say :n-digit :text") do |m|
   m.args[:n].to_i.times do
     m.reply m.args[:text]
   end
 end

This would provide the following output on IRC

 injekt> !say foo bar
 injekt> !say 2 foo bar
 Cinch> foo bar
 Cinch> foo bar

* See Cinch::Base#compile for more information and the available patterns

Cinch also supports custom named parameter patterns. That's right, you can define you own 
pattern. Just like this:

 bot.add_custom_pattern(:friends, /injekt|lee|john|bob/)

 bot.plugin("I like :friend-friends", :prefix => false) do |m|
   m.reply "I like #{m.args[:friend]} too!"
 end

Which would provide the following output on IRC:

 * Cinch has joined #cinch
 injekt> I like spongebob
 injekt> I like bob
 Cinch> I like bob too!

Note though that although Cinch adds the capturing parenthesis for you, you must escape it yourself

== Examples
Check out the /examples directory for basic, yet fully functional out-of-the-box bots.
If you have any examples you'd like to add, please either fork the repo and push your example
before sending me a pull request. Alternatively paste the example and inform me in the IRC 
channel or by email

== Authors
* {Lee Jarvis}[http://injekt.net]

== Notes
* RDoc API documentation is available {here}[http://doc.injekt.net/cinch]
* Issue and feature tracking is available {here}[https://github.com/injekt/cinch/issues]
* Contribution in the form of bugfixes or feature requests is welcome and encouraged

== Contribute
If you'd like to contribute, fork the GitHub repository, make any changes, and send 
{injekt}[http://github.com/injekt] a pull request. Collaborator access is available on
request once one patch has been submitted. Any contribution is welcome and appreciated

== TODO
* More specs
* More documentation

