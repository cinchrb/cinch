require File.dirname(__FILE__) + '/helper'

describe "Cinch::Base" do
  before do
    @base = Cinch::Base.new

    @full = Cinch::Base.new(
      :server => 'irc.freenode.org',
      :nick => 'CinchBot',
      :channels => ['#cinch']
    )
  end

  describe "::new" do 
    it "should add a default ping listener" do
      @base.listeners.should include :ping
    end

    it "should add a 376 listener, only if channels are set" do
      @base.listeners.should_not include :'376'
      @full.listeners.should include :'376'
    end
  end

  describe "#plugin" do 
    it "should compile and add a rule" do
      @base.plugin('foo')
      @base.rules.include?("^foo$").should == true
    end

    it "should add options to an existing rule" do
      @base.plugin('foo') { }
      @base.plugin('foo', :bar => 'baz') { }
      rule = @base.rules.get('^foo$')
      rule.options.should include :bar
    end 

    it "should add its block to an existing rule" do
      @base.plugin('foo') { }
      @base.plugin('foo') { }
      rule = @base.rules.get_rule('^foo$')
      rule.callbacks.size.should == 2
    end
  end

  describe "#on" do
    it "should save a listener" do
      @base.on(:foo) {}
      @base.listeners.should include :foo
    end

    it "should store listener blocks in an Array" do
      @base.listeners[:ping].should be_kind_of Array
    end
  end
end
