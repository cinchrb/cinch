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
      :username => 'cinch',
      :realname => "Cinch IRC Microframework",
      :prefix => '!',
      :usermode => 0,
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
      @listeners = Hash.new([])

      @irc = IRC::Socket.new(options[:server], options[:port])
      @parser = IRC::Parser.new

      # Default listeners
      on(:ping) {|m| @irc.pong(m.text) }
      
      if @options.respond_to?(:channels)
        on(376) { @options.channels.each {|c| @irc.join(c) } }
      end
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
      commands.map {|x| x.to_s.downcase.to_sym }.each do |cmd|
        if @listeners.key?(cmd)
          @listeners[cmd] << blk
        else
          @listeners[cmd] = [blk]
        end
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
      unless @rules.key?(rule)
        @rules[rule] = [rule, keys, options, blk]
      end
    end

    # Run run run
    def run
      @irc.connect
      @irc.nick options.nick
      @irc.user options.username, options.usermode, '*', options.realname
        
      begin
        process(@irc.read) while @irc.connected?
      rescue Interrupt
        @irc.quit("Interrupted")
        puts "\nInterrupted.."
        exit
      end
    end

    # Process the next line read from the server
    def process(line)
      message = @parser.parse(line)
      message.irc = @irc
      puts message if options.verbose

      if @listeners.key?(message.symbol)
        @listeners[message.symbol].each {|l| l.call(message) }
      end

      if [:privmsg].include?(message.symbol)
        rules.each_value do |attr|
          rule, keys, ops, blk = attr
          args = {}

          unless ops.has_key?(:prefix) || options.prefix == false
            rule.insert(1, options.prefix) unless rule[1].chr == options.prefix
          end

          if message.text && mdata = message.text.match(Regexp.new(rule))
            unless keys.empty? || mdata.captures.empty?
              args = Hash[keys.map {|k| k.to_sym}.zip(mdata.captures)]
              message.args = args
            end 
            execute_rule(message, ops, blk)
          end
        end
      end
    end

    # Execute a rule
    def execute_rule(message, ops, blk)
      ops.keys.each do |k|
        case k
        when :nick; return unless ops[:nick] == message.nick
        when :user; return unless ops[:user] == message.user 
        when :host; return unless ops[:host] == message.host
        when :channel
          if message.channel
            return unless ops[:channel] == message.channel
          end
        end
      end

      blk.call(message)    
    end

    # 
    def method_missing(meth, *args, &blk)
      if @irc.respond_to?(meth)
        @irc.send(meth, *args)
      else
        super
      end
    end

    # Option management
    class Options < Hash # :nodoc:
      def initialize(&blk)
        instance_eval(&blk) if block_given?
      end
      def method_missing(meth, *args, &blk)
        self[meth] = args.first unless args.empty?
      end
    end
  end
end

