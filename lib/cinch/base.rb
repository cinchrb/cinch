module Cinch

  # == Author
  # * Lee Jarvis - ljjarvis@gmail.com
  #
  # == Description
  # The base for an IRC connection
  # TODO: More documentation
  #
  # == Example
  #  bot = Cinch::Base.new :server => 'irc.freenode.org'
  #
  #  bot.on :join do |m|
  #    m.reply "Welcome to #{m.channel}, #{m.nick}!" unless m.nick == bot.nick
  #  end
  #
  #  bot.plugin "say :text" do |m|
  #    m.reply m.args[:text]
  #  end
  class Base

    # A Hash holding rules and attributes
    attr_reader :rules
    
    # A Hash holding listeners and reply Procs
    attr_reader :listeners

    # An OpenStruct holding all configuration options
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
    # independantly. Or of course via the command line
    #
    # == Example
    #  # With a Hash
    #  bot = Cinch::Base.new(:server => 'irc.freenode.org')
    #
    #  # With a block
    #  bot = Cinch::Base.new do
    #    server "irc.freenode.org"
    #  end
    #
    #  # After the instance is created
    #  bot = Cinch::Base.new
    #  bot.options.server = "irc.freenode.org"
    #
    #  # Nothing, but invoked with "ruby foo.rb -s irc.freenode.org"
    #  bot = Cinch::Base.new
    def initialize(ops={}, &blk)
      options = DEFAULTS.merge(ops).merge(Options.new(&blk))
      @options = OpenStruct.new(options.merge(cli_ops))

      @rules = Rules.new
      @listeners = {}

      @irc = IRC::Socket.new(options[:server], options[:port])
      @parser = IRC::Parser.new

      # Default listeners
      on(:ping) {|m| @irc.pong(m.text) }
      
      if @options.respond_to?(:channels)
        on(376) { @options.channels.each {|c| @irc.join(c) } }
      end
    end

    # Parse command line options
    def cli_ops
      options = {}
      if ARGV.any?
        begin
          OptionParser.new do |op|
            op.on("-s server") {|v| options[:server] = v }
            op.on("-p port") {|v| options[:port] = v.to_i }
            op.on("-n nick") {|v| options[:nick] = v }
            op.on("-c command_prefix") {|v| options[:prefix] = v }
            op.on("-v", "--verbose", "Enable verbose mode") {|v| options[:verbose] = true }
            op.on("-j", "--channels x,y,z", Array, "Autojoin channels") {|v| 
              options[:channels] = v.map {|c| %w(# + &).include?(c[0].chr) ? c : c.insert(0, '#') } 
            }
          end.parse(ARGV)
        rescue OptionParser::MissingArgument => err
          warn "Missing values for options: #{err.args.join(', ')}\nFalling back to default"
        rescue OptionParser::InvalidOption => err
          warn err.message
          exit
        end
      end
      options
    end

    # Add a new plugin
    #
    # == Example
    #  plugin('hello') do |m|
    #    m.reply "Hello, #{m.nick}!"
    #  end
    def plugin(rule, options={}, &blk)
      rule, keys = compile(rule)
      
      if @rules.has_rule?(rule)
        @rules.add_callback(rule, blk)
        @rules.merge_options(rule, options)
      else
        @rules.add_rule(rule, keys, options, blk)
      end
    end
    
    # Add new listeners
    #
    # == Example
    #  on(376) do |m|
    #    m.join "#mychan"
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
        when *special_chars
          Regexp.escape(match)
        else
          keys << $2[1..-1]
          "([^\x00\r\n]+?)"
        end
      end
      ["^#{pattern}$", keys]
    end

    # Run run run
    def run      
      @irc.connect options.server, options.port
      @irc.nick options.nick
      @irc.user options.username, options.usermode, '*', options.realname
        
      begin
        process(@irc.read) while @irc.connected?
      rescue Interrupt
        @irc.quit("Interrupted")
        puts "\nInterrupted. Shutting down.."
        exit
      end
    end

    # Process the next line read from the server
    def process(line)
      return unless line
      message = @parser.parse(line)
      message.irc = @irc
      puts message if options.verbose

      if @listeners.key?(message.symbol)
        @listeners[message.symbol].each {|l| l.call(message) }
      end

      if [:privmsg].include?(message.symbol)
        rules.each do |rule|
          unless rule.options.key?(:prefix) || options.prefix == false
            rule.to_s.insert(1, options.prefix) unless rule.to_s[1].chr == options.prefix
          end

          if message.text && mdata = message.text.match(Regexp.new(rule.to_s))
            unless rule.keys.empty? || mdata.captures.empty?
              args = Hash[rule.keys.map {|k| k.to_sym}.zip(mdata.captures)]
              message.args = args
            end
            # execute rule
            rule.execute(message)
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

    # Catch methods
    def method_missing(meth, *args, &blk) # :nodoc:
      if options.respond_to?(meth)
        options.send(meth)
      elsif @irc.respond_to?(meth)
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

