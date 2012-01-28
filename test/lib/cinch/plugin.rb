require "helper"

module Cinch
  class CinchTestPluginWithoutName
    include Cinch::Plugin
  end
end

class PluginTest < TestCase
  def setup
    @bot = Cinch::Bot.new {
      self.loggers.clear
    }
    @plugin = Class.new { include Cinch::Plugin }
    @bot.config.plugins.options = {@plugin => {:key => :value}}

    @plugin.plugin_name = "testplugin"
    @plugin_instance = @plugin.new(@bot)
  end

  test "should be able to specify matchers" do
    @plugin.match(/pattern/)
    matcher = @plugin.matchers.last

    assert_equal(1, @plugin.matchers.size, "Shoult not forget existing matchers")
    assert_equal Cinch::Plugin::ClassMethods::Matcher.new(/pattern/, true, true, :execute), matcher

    matcher = @plugin.match(/pattern/, use_prefix: false, use_suffix: false, method: :some_method)
    assert_equal Cinch::Plugin::ClassMethods::Matcher.new(/pattern/, false, false, :some_method), matcher
  end

  test "should be able to listen to events" do
    @plugin.listen_to(:event1, :event2)
    @plugin.listen_to(:event3, method: :some_method)

    listeners = @plugin.listeners
    assert_equal 3, listeners.size
    assert_equal [:event1, :event2, :event3], listeners.map(&:event)
    assert_equal [:listen, :listen, :some_method], listeners.map(&:method)
  end

  test "should be able to create CTCP commands" do
    @plugin.ctcp("FOO")
    @plugin.ctcp("BAR")

    assert_equal 2, @plugin.ctcps.size
    assert_equal ["FOO", "BAR"], @plugin.ctcps
  end

  test "CTCP commands should always be uppercase" do
    @plugin.ctcp("foo")
    assert_equal "FOO", @plugin.ctcps.last
  end

  test "should return an empty array of timers" do
    assert_equal [], @plugin.timers
  end

  test "should return an empty array of listeners" do
    assert_equal [], @plugin.listeners
  end

  test "should return an empty array of CTCPs" do
    assert_equal [], @plugin.ctcps
  end

  test "should be able to set timers" do
    @plugin.timer(1, method: :foo)
    @plugin.timer(2, method: :bar, :threaded => false)

    timers = @plugin.timers
    assert_equal 2, timers.size
    assert_equal [1, 2], timers.map(&:interval)
    assert_equal [:foo, :bar], timers.map {|t| t.options[:method]}
    assert_equal [true, false], timers.map {|t| t.options[:threaded]}
  end

  test "should be able to register hooks" do
    @plugin.hook(:pre)
    @plugin.hook(:post, :for => [:match])
    @plugin.hook(:post, :method => :some_method)

    hooks = @plugin.hooks.values.flatten
    assert_equal [:pre, :post, :post], hooks.map(&:type)
    assert_equal [:match], hooks[1].for
    assert_equal :some_method, hooks.last.method
    assert_equal :hook, hooks.first.method
  end

  test "should have access to plugin configuration" do
    assert_equal :value, @plugin_instance.config[:key]
  end

  test "should be able to set a prefix with a block" do
    block = lambda {|m| "^"}
    @plugin.prefix = block
    assert_equal block, @plugin.prefix
  end

  test "should be able to set a suffix with a block" do
    block = lambda {|m| "^"}
    @plugin.suffix = block
    assert_equal block, @plugin.suffix
  end

  test "should support `set(key, value)`" do
    @plugin.set :help,        "some help message"
    @plugin.set :prefix,      "some prefix"
    @plugin.set :suffix,      "some suffix"
    @plugin.set :plugin_name, "some plugin"
    @plugin.set :reacting_on,    :event1

    assert_equal "some help message", @plugin.help
    assert_equal "some prefix",       @plugin.prefix
    assert_equal "some suffix",       @plugin.suffix
    assert_equal "some plugin",       @plugin.plugin_name
    assert_equal :event1,             @plugin.reacting_on
  end

  test "should support `set(key => value, key => value, ...)`" do
    @plugin.set(:help        => "some help message",
                :prefix      => "some prefix",
                :suffix      => "some suffix",
                :plugin_name => "some plugin",
                :reacting_on    => :event1)

    assert_equal "some help message", @plugin.help
    assert_equal "some prefix",       @plugin.prefix
    assert_equal "some suffix",       @plugin.suffix
    assert_equal "some plugin",       @plugin.plugin_name
    assert_equal :event1,             @plugin.reacting_on
  end

  test "should support `self.key = value`" do
    @plugin.help        = "some help message"
    @plugin.prefix      = "some prefix"
    @plugin.suffix      = "some suffix"
    @plugin.plugin_name = "some plugin"
    @plugin.reacting_on    = :event1

    assert_equal "some help message", @plugin.help
    assert_equal "some prefix",       @plugin.prefix
    assert_equal "some suffix",       @plugin.suffix
    assert_equal "some plugin",       @plugin.plugin_name
    assert_equal :event1,             @plugin.reacting_on
  end

  test "should support querying attributes" do
    @plugin.plugin_name = "foo"
    @plugin.help = "I am a help message"
    @plugin.prefix = "^"
    @plugin.suffix = "!"
    @plugin.react_on(:event1)

    assert_equal "foo", @plugin.plugin_name
    assert_equal "I am a help message", @plugin.help
    assert_equal "^", @plugin.prefix
    assert_equal "!", @plugin.suffix
    assert_equal :event1, @plugin.reacting_on
  end

  test "should have a default name" do
    assert_equal "cinchtestpluginwithoutname", Cinch::CinchTestPluginWithoutName.plugin_name
  end

  test "should check for the right number of arguments for `set`" do
    assert_raises(ArgumentError) { @plugin.set() }
    assert_raises(ArgumentError) { @plugin.set(1, 2, 3) }
  end
end
