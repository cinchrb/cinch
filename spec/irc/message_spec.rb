require File.dirname(__FILE__) + '/helper'

describe "IRC::Message" do
  before do
    @message = Cinch::IRC::Message.new('rawline', 'prefix', 'COMMAND', 'foo bar params')
  end

  describe "::new" do
    it "should return a Cinch::IRC::Message" do
      @message.class.should == Cinch::IRC::Message
    end
  end

  describe "#add, #[]=" do
    it "should add an attribute" do
      @message.add(:custom, 'something')
      @message.data.should include :custom
      @message.data[:custom].should == "something"
    end
  end

  describe "#delete" do
    it "should remove an attribute" do
      @message.add(:custom, 'something')
      @message.delete(:custom)
      @message.data.should_not include :custom
    end
  end

  describe "#method_missing" do
    it "should return an attribute if it exists" do
      @message.add(:custom, 'something')
      @message.custom.should == 'something'
    end

    it "should raise NoMethodError if no attribute exists" do
      lambda { @message.foobar }.should raise_error(NoMethodError)
    end
  end

  describe "default attributes" do
    it "should contain a prefix" do
      @message.prefix.should == 'prefix'
    end

    it "should contain a command" do
      @message.command.should == "COMMAND"
    end

    it "should contain params" do
      @message.params.should == "foo bar params"
    end

    it "should contain a symbolized command" do
      @message.symbol.should == :command
    end
  end

end

