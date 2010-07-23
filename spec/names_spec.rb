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
      
      it 'should not issue a names command to the channel' do
        @bot.should_receive(:names).never
        @listener.call(@message)
      end
      
      describe 'and the joiner is the bot' do
        before :each do
          @message.nick = @bot.nick
        end
        
        it 'should not add the nick to the name list' do
          @listener.call(@message)
          @bot.channel_names[@message.channel].should_not include(@message.nick)
        end
        
        it 'should issue a names command to the channel' do
          @bot.should_receive(:names).with(@message.channel)
          @listener.call(@message)
        end
      end
    end
    
    it 'should provide a names listener' do
      @bot.listeners[:'353'].should_not be_nil
    end
    
    describe 'names listener' do
      before :each do
        @listener = @bot.listeners[:'353'].first
        @nick_text = 'cardroid admc cldwalker bmizerany'
        @nicks = %w[cardroid admc cldwalker bmizerany]
        @channel = '#github'
        @message = Struct.new(:params, :text).new(['cardroid', '@', @channel, @nick_text], @nick_text)
      end
      
      it 'should be callable' do
        @listener.should respond_to(:call)
      end
      
      it 'should set the channel name list to the given nick list' do
        @listener.call(@message)
        @bot.channel_names[@channel].should == @nicks
      end
      
      it 'should add the given nicks to an already-present channel name list' do
        nicks = %w[other people already present]
        @bot.instance_variable_set('@channel_names', { @channel => nicks.dup })
        
        @listener.call(@message)
        @bot.channel_names[@channel].should == (nicks + @nicks)
      end
      
      it 'should not affect any other channel name lists' do
        channel_names = { '#otherchan' => %w[some people], @channel => [] }
        @bot.instance_variable_set('@channel_names', channel_names.dup)
        @listener.call(@message)
        @bot.channel_names.should == { '#otherchan' => %w[some people], @channel => @nicks }
      end
      
      it 'should strip extra marking characters from the given nick list' do
        nick_text = 'cardroid admc cldwalker bmizerany programble @luckiestmonkey @tekkub binjured ceej'
        nicks = %w[cardroid admc cldwalker bmizerany programble luckiestmonkey tekkub binjured ceej]
        @message.params[-1] = nick_text
        @message.text       = nick_text
        
        @listener.call(@message)
        @bot.channel_names[@channel].should == nicks
      end
    end

    it 'should provide a part listener' do
      @bot.listeners[:part].should_not be_nil
    end
    
    describe 'part listener' do
      before :each do
        @listener = @bot.listeners[:part].first
        @message = Struct.new(:nick, :channel).new('someguy', '#somechan')
        
        @bot.instance_variable_set('@channel_names', { @message.channel => [] })
      end
      
      it 'should be callable' do
        @listener.should respond_to(:call)
      end
      
      it "should remove the parter's nick from the channel name list" do
        @nicks = %w[bunch of people]
        @bot.instance_variable_set('@channel_names', { @message.channel => (@nicks + [@message.nick]) })
        
        @listener.call(@message)
        @bot.channel_names[@message.channel].should == @nicks
      end
      
      it "should remove the parter's nick from the channel name list no matter where or how many times it occurs" do
        @nicks = %w[bunch of people]
        @bot.instance_variable_set('@channel_names', { @message.channel => @nicks.join(" #{@message.nick} ").split })
        
        @listener.call(@message)
        @bot.channel_names[@message.channel].should == @nicks
      end
      
      it 'should not affect any other channel name lists' do
        @nicks = %w[bunch of people]
        channel_names = { '#otherchan' => %w[some people], @message.channel => (@nicks + [@message.nick]) }
        @bot.instance_variable_set('@channel_names', channel_names.dup)
        @listener.call(@message)
        @bot.channel_names.should == { '#otherchan' => %w[some people], @message.channel => @nicks }
      end
      
      it 'should handle the channel names not already tracking the channel' do
        @bot.instance_variable_set('@channel_names', {})
        @listener.call(@message)
        @bot.channel_names[@message.channel].should == []
      end
      
      it 'should handle the nick not appearing on the list' do
        @nicks = %w[bunch of people]
        @bot.instance_variable_set('@channel_names', { @message.channel => @nicks.dup })
        
        @listener.call(@message)
        @bot.channel_names[@message.channel].should == @nicks
      end

      describe 'and the parter is the bot' do
        before :each do
          @message.nick = @bot.nick
        end
        
        it 'should completely remove the channel from the names hash' do
          channel_names = { '#otherchan' => %w[some people], @message.channel => %w[bunch of people] }
          @bot.instance_variable_set('@channel_names', channel_names.dup)
          @listener.call(@message)
          @bot.channel_names.should == { '#otherchan' => %w[some people] }
        end
      end
    end
    
    it 'should provide a quit listener' do
      @bot.listeners[:quit].should_not be_nil
    end
    
    describe 'quit listener' do
      before :each do
        @listener = @bot.listeners[:quit].first
        @message = Struct.new(:nick).new('someguy')
        @channel = '#somechan'
        @nicks = %w[bunch of people]
        @other_chan = '#otherchan'
        @other_nicks = %w[other people here]
      end
      
      it 'should be callable' do
        @listener.should respond_to(:call)
      end
      
      it "should remove the quitter's nick from every channel name list" do
        @bot.instance_variable_set('@channel_names', { @channel => (@nicks + [@message.nick]), @other_chan => (@other_nicks + [@message.nick]) })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => @nicks, @other_chan => @other_nicks }
      end
      
      it "should remove the quitter's nick from every channel name list no matter where or how many times it occurs" do
        @bot.instance_variable_set('@channel_names', { @channel => @nicks.join(" #{@message.nick} ").split, @other_chan => @other_nicks.join(" #{@message.nick} ").split })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => @nicks, @other_chan => @other_nicks }
      end
      
      it 'should not affect any other channel name lists' do
        @bot.instance_variable_set('@channel_names', { @channel => (@nicks + [@message.nick]), @other_chan => @other_nicks.dup })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => @nicks, @other_chan => @other_nicks }
      end
    end
    
    it 'should provide a kill listener' do
      @bot.listeners[:kill].should_not be_nil
    end
    
    describe 'kill listener' do
      before :each do
        @listener = @bot.listeners[:kill].first
        @message = Struct.new(:nick).new('someguy')
        @channel = '#somechan'
        @nicks = %w[bunch of people]
        @other_chan = '#otherchan'
        @other_nicks = %w[other people here]
      end
      
      it 'should be callable' do
        @listener.should respond_to(:call)
      end
      
      it 'should remove the killed nick from every channel name list' do
        @bot.instance_variable_set('@channel_names', { @channel => (@nicks + [@message.nick]), @other_chan => (@other_nicks + [@message.nick]) })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => @nicks, @other_chan => @other_nicks }
      end
      
      it 'should remove the killed nick from every channel name list no matter where or how many times it occurs' do
        @bot.instance_variable_set('@channel_names', { @channel => @nicks.join(" #{@message.nick} ").split, @other_chan => @other_nicks.join(" #{@message.nick} ").split })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => @nicks, @other_chan => @other_nicks }
      end
      
      it 'should not affect any other channel name lists' do
        @bot.instance_variable_set('@channel_names', { @channel => (@nicks + [@message.nick]), @other_chan => @other_nicks.dup })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => @nicks, @other_chan => @other_nicks }
      end
    end
    
    it 'should provide a nick listener' do
      @bot.listeners[:nick].should_not be_nil
    end
    
    describe 'nick listener' do
      before :each do
        @listener = @bot.listeners[:nick].first
        @message = Struct.new(:nick, :recipient).new('someguy', 'someotherguy')
        @channel = '#somechan'
        @nicks = %w[bunch of people]
        @other_chan = '#otherchan'
        @other_nicks = %w[other people here]
      end
      
      it 'should be callable' do
        @listener.should respond_to(:call)
      end
      
      it 'should replace the changed nick in every channel name list' do
        @bot.instance_variable_set('@channel_names', { @channel => (@nicks + [@message.nick]), @other_chan => (@other_nicks + [@message.nick]) })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => (@nicks + [@message.recipient]), @other_chan => (@other_nicks + [@message.recipient]) }
      end
      
      it 'should replace the the changed nick in every channel name list no matter where or how many times it occurs' do
        @bot.instance_variable_set('@channel_names', { @channel => @nicks.join(" #{@message.nick} ").split, @other_chan => @other_nicks.join(" #{@message.nick} ").split })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => (@nicks + [@message.recipient]), @other_chan => (@other_nicks + [@message.recipient]) }
      end
    
      it 'should not affect any other channel name lists' do
        @bot.instance_variable_set('@channel_names', { @channel => (@nicks + [@message.nick]), @other_chan => @other_nicks.dup })
        
        @listener.call(@message)
        @bot.channel_names.should == { @channel => (@nicks + [@message.recipient]), @other_chan => @other_nicks }
      end
    end
  end
  
  describe 'before tracking names' do
    it 'should have no channel name list' do
      @bot.channel_names.should be_nil
    end
    
    it 'should have no join listener' do
      @bot.listeners[:join].should be_nil
    end
    
    it 'should have no names listener' do
      @bot.listeners[:'353'].should be_nil
    end
    
    it 'should have no part listener' do
      @bot.listeners[:part].should be_nil
    end
    
    it 'should have no quit listener' do
      @bot.listeners[:quit].should be_nil
    end
    
    it 'should have no kill listener' do
      @bot.listeners[:kill].should be_nil
    end
    
    it 'should have no nick listener' do
      @bot.listeners[:nick].should be_nil
    end
  end
end
