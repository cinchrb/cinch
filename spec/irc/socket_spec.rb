require File.dirname(__FILE__) + '/helper'

class Cinch::IRC::Socket
  def write(data)
    return data
  end

  def read(chompstr="\r\n")
    str = "foo bar baz\r\n"
    str.chomp!(chompstr) if chompstr
  end
end

commands = [
  [:pass,    %w(foobar),                        "PASS foobar"],
  [:nick,    %(ipsum),                          "NICK ipsum"],
  [:user,    ["guest", 0, '*', "real name"],    "USER guest 0 * :real name"],
  [:oper,    %w(foo bar),                       "OPER foo bar"],
  [:mode,    %w(#foo +v bar),                   "MODE #foo +v bar"],
  [:quit,    %w(goodbye),                       "QUIT :goodbye"],
  [:join,    %w(#mychan),                       "JOIN #mychan"],
  [:part,    %w(#mychan),                       "PART #mychan"],
  [:part,    %w(#mychan cya!),                  "PART #mychan :cya!",           "with part message"],
  [:topic,   %w(#mychan newtopic),              "TOPIC #mychan :newtopic"],
  [:names,   %w(#foo #bar),                     "NAMES #foo,#bar"],
  [:list,    %w(#foo #bar),                     "LIST #foo,#bar"],
  [:invite,  %w(foo #mychan),                   "INVITE foo #mychan"],
  [:kick,    %w(#chan villian),                 "KICK #chan villian"],
  [:kick,    %w(#chan villian gtfo!),           "KICK #chan villian :gtfo!",    "with kick reason"],
  [:privmsg, ['#chan', 'foo bar baz'],          "PRIVMSG #chan :foo bar baz"],
  [:notice,  ['#chan', 'foo bar baz'],          "NOTICE #chan :foo bar baz"],
  [:motd,    %w(someserver),                    "MOTD someserver"],
  [:version, %w(anotherserver),                 "VERSION anotherserver"],
  [:stats,   %w(m server),                      "STATS m server"],
  [:time,    %w(irc.someserver.net),            "TIME irc.someserver.net"],
  [:info,    %w(foobar),                        "INFO foobar"],
  [:squery,  %w(irchelp HELPME),                "SQUERY irchelp :HELPME"],
  [:who,     %w(*.com o),                       "WHO *.com o"],
  [:whois,   %w(foo.org user),                  "WHOIS foo.org user"],
  [:whowas,  %w(foo.org user),                  "WHOWAS foo.org user"],
  [:kill,    ['badperson', 'get out!'],         "KILL badperson :get out!"],
  [:ping,    %w(010123444),                     "PING 010123444"],
  [:pong,    %w(irc.foobar.org),                "PONG irc.foobar.org"],
  [:away,    [],                                "AWAY"],
  [:away,    ['gone for lunch'],                "AWAY :gone for lunch"],
  [:users,   %w(irc.foobar.org),                "USERS irc.foobar.org"],
  [:userhost, %w(foo bar baz),                  "USERHOST foo bar baz"],
]

describe "Cinch::IRC::Socket" do
  before do
    @irc = Cinch::IRC::Socket.new('irc.myserver.net')
  end

  describe "::new" do
    it "should return an Cinch::IRC::Socket" do
      @irc.class.should == Cinch::IRC::Socket
    end

    it "should default to port 6667" do
      @irc.port.should == 6667
    end

    it "should not automatically connect" do
      @irc.connected.should == false
    end

    it "should set socket instance as nil" do
      @irc.socket.should == nil
    end
  end

  describe "#read" do
    it "should chomp CRLF by default" do
      @irc.read.should == "foo bar baz"
      @irc.read.should_not == "foo bar baz\r\n"
    end
  end

  commands.each do |requirements|
    meth, params, pass, extra = *requirements
    describe "##{meth}" do
      it "should send a #{meth.to_s.upcase} command #{extra if extra}" do
        @irc.send(meth, *params).should == pass
      end
    end
  end

end

