require File.dirname(__FILE__) + '/helper'

describe "Cinch::Rules" do
  before do
    @rules = Cinch::Rules.new
    @rules.add_rule('foo', [], {}, Proc.new{})
  end

  describe "::new" do
    it "should define an empty set of rules" do
      Cinch::Rules.new.empty?.should == true
    end
  end

  describe "#add_rule" do
    it "should add a new rule" do
      @rules.add_rule('bar', [], {}, Proc.new{})
      @rules.all.should include 'foo'
    end

    it "should replace an existing rule" do
      @rules.add_rule('foo', [], {}, Proc.new{})
      @rules.count.should == 1
    end
  end

  describe "#get_rule" do
    it "should return a Cinch::Rule" do
      @rules.get_rule('foo').should be_kind_of Cinch::Rule
    end
  end

  describe "#remove_rule" do
    it "should remove a rule" do
      @rules.remove_rule('foo')
      @rules.include?('foo').should == false
      @rules.count.should == 0
    end
  end

  describe "#add_callback" do
    it "should add a callback for a rule" do
      @rules.add_callback('foo', Proc.new{})
      rule = @rules.get_rule('foo')
      rule.callbacks.size.should == 2
    end
  end

  describe "#add_option" do
    it "should add an option for a rule" do
      @rules.add_option('foo', :nick, 'injekt')
      rule = @rules.get('foo')
      rule.options.should include :nick
      rule.options[:nick].should == 'injekt'
    end
  end

  describe "#include?" do
    it "should check if a rule exists" do
      @rules.include?('foo').should == true
    end
  end

  describe "#clear" do
    it "should clear all rules" do
      @rules.clear
      @rules.empty?.should == true
    end
  end

  describe "#empty?" do
    it "should check if any rules exist" do
      @rules.empty?.should == false
      @rules.clear
      @rules.empty?.should == true
    end
  end

  describe "#count" do
    it "should show how many rules exist" do
      @rules.count.should == 1
      @rules.add_rule('bar', [], {}, Proc.new{})
      @rules.count.should == 2
    end
  end

  describe "#all" do
    it "should return a Hash of all rules" do
      @rules.all.should be_kind_of Hash
      @rules.all.should include 'foo'
    end
  end

  describe "#to_a" do
    it "should return an Array of rules" do
      @rules.to_a.should be_kind_of Array
      @rules.to_a.include?('foo').should == true
    end
  end
end

