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
  end
end

