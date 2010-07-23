require File.dirname(__FILE__) + '/helper'

describe Cinch::Base do
  before :each do
    @bot = Cinch::Base.new
  end
  
  it 'should be able to track names' do
    @bot.should respond_to(:track_names)
  end
  
  describe 'when tracking names' do
    before :each do
      @bot.track_names
    end
    
    it 'should provide access to the stored channel names' do
      @bot.should respond_to(:channel_names)
    end
    
    it 'should initialize the stored channel names as a hash' do
      @bot.channel_names.should == {}
    end
    
    it 'should provide a join listener' do
      @bot.listeners[:join].should_not be_nil
    end
    
    describe 'join listener' do
      before :each do
        @listener = @bot.listeners[:join].first
        @message = Struct.new(:nick, :channel).new('someguy', '#somechan')
        
        @bot.instance_variable_set('@channel_names', { @message.channel => [] })
      end
      
      it 'should be callable' do
        @listener.should respond_to(:call)
      end
      
      it "should add the joiner's nick to the channel name list" do
        @listener.call(@message)
        @bot.channel_names[@message.channel].should == [@message.nick]
      end
      
      it "should not remove any already-present nicks in the channel name list" do
        nicks = %w[tom mary joe]
        @bot.instance_variable_set('@channel_names', { @message.channel => nicks.dup })
        @listener.call(@message)
        @bot.channel_names[@message.channel].sort.should == (nicks + [@message.nick]).sort
      end
      
      it 'should not affect any other channel name lists' do
        channel_names = { '#otherchan' => %w[some people], @message.channel => [] }
        @bot.instance_variable_set('@channel_names', channel_names.dup)
        @listener.call(@message)
        @bot.channel_names.should == { '#otherchan' => %w[some people], @message.channel => [@message.nick] }
      end
      
      it 'should handle the channel names not already tracking the channel' do
        @bot.instance_variable_set('@channel_names', {})
        @listener.call(@message)
        @bot.channel_names[@message.channel].should == [@message.nick]
      end
    end
  end
end
