require File.dirname(__FILE__) + '/helper'

describe "IRC::Message" do
  before do
    @message = Cinch::IRC::Message.new('rawline', 'prefix', 'COMMAND', ['#chan', 'hello world'])
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

  describe "#to_s" do
    it "should return the raw IRC message" do
      @message.to_s.should == @message.raw
    end
  end

  describe "#method_missing" do
    it "should return an attribute if it exists" do
      @message.add(:custom, 'something')
      @message.custom.should == 'something'
    end

    it "should return nil if no attribute exists" do
      @message.foobar.should == nil
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
      @message.params.should be_kind_of(Array)
      @message.params.size.should == 2
    end

    it "should contain a symbolized command" do
      @message.symbol.should == :command
    end
  end

end

