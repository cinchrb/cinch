module Cinch

  # == Author
  # * Lee Jarvis - ljjarvis@gmail.com
  #
  # == Description
  #
  # == Example
  #
  class Base

    attr_reader :rules, :listeners
    attr_reader :options

    # Default options hash
    DEFAULTS = {
      :port => 6667,
      :nick => "Cinch",
      :realname => "Cinch IRC Microframework",
      :prefix => '!',
    }

    # Options can be passed via a hash, a block, or on the instance
    # independantly
    #
    # == Example
    #  # With a Hash
    #  irc = Cinch::Base.new(:server => 'irc.freenode.org')
    #
    #  # With a block
    #  irc = Cinch::Base.new do
    #    server "irc.freenode.org"
    #  end
    #
    #  # After the instance is created
    #  irc = Cinch::Base.new
    #  irc.options.server = "irc.freenode.org"
    def initialize(ops={}, &blk)
      options = DEFAULTS.merge(ops).merge(Options.new(&blk))
      @options = OpenStruct.new(options)

      @rules = {}
      @listeners = {}

      @irc = IRC::Socket.new(options[:server], options[:port])
    end

    # Add a new plugin
    #
    # == Example
    #  plugin('hello') do |m|
    #    reply "Hello, #{m.nick}!"
    #  end
    def plugin(rule, options={}, &blk)
      rule, keys = compile(rule)
      add_rule(rule, keys, options, &blk)
    end
    
    # Add new listeners
    #
    # == Example
    #  on(376) do 
    #    join "#mychan"
    #  end
    def on(*commands, &blk)
      commands.map {|x| x.downcase.to_s.to_sym }.each do |cmd|
        add_listener(cmd, &blk)
      end
    end

    # Compile a rule string into regexp
    def compile(rule)
      return [rule []] if rule.is_a?(Regexp)
      keys = []
      special_chars = %w{. + ( )}

      pattern = rule.to_s.gsub(/((:\w+)|[\*#{special_chars.join}])/) do |match|
        case match
        when "*"
          keys << "splat"
          "(.*?)"
        when *special_chars
          Regexp.escape(match)
        else
          keys << $2[1..-1]
          "([^\x00\r\n]+?)"
        end
      end
      ["^#{pattern}$", keys]
    end

    # Add a new rule, or add to an existing one if it
    # already exists
    def add_rule(rule, keys, options={}, &blk)
      p [rule, keys, options, blk]
    end

    # Add a new listener, should only be used by #on
    def add_listener(command, &blk)
      if @listeners.key?(command)
        @listeners[command] << blk
      else
        @listeners[command] = [blk]
      end
    end

    # Run run run
    def run
      @irc.connect
      @irc.nick options[:nick]
      @irc.user *options.values_at(:user, :host, :real)
      process(@irc.read) while @irc.connected?
    end


    # Option management
    class Options < Hash
      def initialize(&blk)
        instance_eval(&blk) if block_given?
      end
      def method_missing(meth, *args, &blk)
        self[meth] = args.first unless args.empty?
      end
    end
  end
end

