require File.dirname(__FILE__) + '/helper'

describe "Cinch::Base options" do
  before do
    @base = Cinch::Base
  end
  
  it "should set options via a hash" do
    base = @base.new(:server => 'irc.foobar.org')
    base.options.server.should == "irc.foobar.org"
  end

  it "should set options via a block" do
    base = @base.new do
      server "irc.foobar.org"
    end
    base.options.server.should == "irc.foobar.org"
  end

  it "should set options via setters" do
    base = @base.new
    base.options.server = "irc.foobar.org"
    base.options.server.should == "irc.foobar.org"
  end

  it "should set specific default values" do 
    defaults = {
      :port => 6667,
      :nick => 'Cinch',
      :nick_suffix => '_',
      :username => 'cinch',
      :realname => 'Cinch IRC Microframework',
      :usermode => 0,
      :prefix => '!',
      :password => nil,
    }

    base = @base.new
    defaults.each do |k, v|
      base.options.send(k).should == v
    end
  end

end

