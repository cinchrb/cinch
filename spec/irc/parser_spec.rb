require File.dirname(__FILE__) + '/helper'

# Common commands
commands = {
  :ping => "PING :foobar",
  :nick => ":foo!~baz@host.com NICK Baz",
  :join => ":foo!~bar@host.com JOIN #baz",

  :privmsg => {
    "to a channel" => ":foo!~bar@host.com PRIVMSG #baz :hello world",
    "to a user" => ":foo!~bar@host.com PRIVMSG Baz :hello world",
    "with an action" => ":foo!~bar@host.com PRIVMSG #baz :\001ACTION hello word\001",
  },

  :notice => {
    "to a channel" => ":foo!~bar@host.com NOTICE #baz :hello world",
    "to a user" => ":foo!~bar@host.com NOTICE Baz :hello world",
  },

  :part => {
    "without a message" => ":foo!~bar@host.com PART #baz",
    "with a message" => ":foo!~bar@host.com PART #baz :beer",
  },

  :quit => {
    "without a message" => ":foo!~bar@host.com QUIT",
    "with a message" => ":foo!~bar@host.com QUIT :baz"
  }
}

describe "IRC::Parser" do
  before do
    @parser = Cinch::IRC::Parser.new
  end

  describe "#add_pattern" do
    it "should add a pattern" do
      @parser.add_pattern(:custom, /foo/)
      @parser.patterns.key?(:custom)
    end

    it "should raise ArgumentError if pattern is not Regexp" do
      lambda { @parser.add_pattern(:custom, 'foo') }.should raise_error(ArgumentError)
    end
  end

  describe "#remove_pattern" do
    it "should remove a pattern" do
      @parser.add_pattern(:custom, /foo/)
      @parser.remove_pattern(:custom)
      @parser.patterns.keys.should_not include(:custom)
    end

    it "should return nil if a pattern doesn't exist" do
      @parser.remove_pattern(:foo).should be nil
    end
  end

  describe "#parse_servermessage" do
    it "should return an IRC::Message" do
      @parser.parse("foo :bar").should be_kind_of(Cinch::IRC::Message)
    end

    it "should raise if given an invalid message" do 
      lambda { @parser.parse("#") }.should raise_error(ArgumentError)
    end

    commands.each do |cmd, passes|
      if passes.is_a?(Hash)
        passes.each do |extra, pass|
          it "should parse a #{cmd.to_s.upcase} command #{extra}" do
            m = @parser.parse(pass)
            m.symbol.should == cmd
          end
        end
      else
        it "should parse a #{cmd.to_s.upcase} command" do
          m = @parser.parse(passes)
          m.symbol.should == cmd
        end
      end
    end

  end

  describe "#parse_userhost" do
    it "should return an Array" do
      @parser.parse_userhost(":foo!bar@baz").should be_kind_of(Array)
    end

    it "should return 3 values" do
      @parser.parse_userhost(":foo!bar@baz").size.should be 3
    end
  end

  describe "#valid_channel?" do
    it "should return true with a valid channel name" do
      @parser.valid_channel?("#foo").should be true
    end

    it "should return false with an invalid channel name" do
      @parser.valid_channel?("foo").should be false
    end
  end

end

