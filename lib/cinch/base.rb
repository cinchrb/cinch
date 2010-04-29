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
      :password => nil
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
      @custom_patterns = {}

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
            op.on("-C", "--channels x,y,z", Array, "Autojoin channels") {|v|
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

    # This method builds a regular expression from your rule
    # and defines all named parameters, as well as dealing with
    # patterns.
    #
    # So far 3 patterns are supported:
    #
    # * word - matches [a-zA-Z_]+
    # * string - matches \w+
    # * digit - matches \d+
    # * lower - matches [a-z]+
    # * upper - matches [A-Z]+
    #
    # == Examples
    # For capturing individual words
    #  bot.plugin("say :text-word")
    # * Does match !say foo
    # * Does not match !say foo bar baz
    #
    # For capturing digits
    #  bot.plugin("say :text-digit")
    # * Does match !say 3
    # * Does not match !say 3 4
    # * Does not match !say foo
    #
    # For both
    #  bot.plugin("say :n-digit :text-word")
    # * Does match !say 3 foo
    # * Does not match !say 3 foo bar
    #
    # For capturing until the end of the line
    #  bot.plugin("say :text")
    # * Does match !say foo
    # * Does match !say foo bar
    #
    # Or mix them all
    #  bot.plugin("say :n-digit :who-word :text")
    #
    # Using "!say 3 injekt some text here" would provide
    # the following attributes
    # m.args[:n] => 3
    # m.args[:who] => injekt
    # m.args[:text] => some text here
    def compile(rule)
      return [rule, []] if rule.is_a?(Regexp)
      keys = []
      special_chars = %w{. + ( )}

      pattern = rule.to_s.gsub(/((:[\w\-]+)|[\*#{special_chars.join}])/) do |match|
        case match
        when *special_chars
          Regexp.escape(match)
        else
          k = $2
          if k =~ /\-(\w+)$/
            key, type = k.split('-')
            keys << key[1..-1]

            case type
            when 'digit'; "(\\d+?)"
            when 'word'; "([a-zA-Z_]+?)"
            when 'string'; "(\\w+?)"
            when 'upper'; "([A-Z]+?)"
            when 'lower'; "([a-z]+?)"
            else
              if @custom_patterns.include?(type)
                @custom_patterns[type]
              else
                "([^\x00\r\n]+?)"
              end
            end
          else
            keys << k[1..-1]
            "([^\x00\r\n]+?)"
          end
        end
      end
      ["^#{pattern}$", keys]
    end

    # Add a custom 'type', for rule validation
    #
    # == Example
    # bot = Cinch.setup do
    #   server 'irc.freenode.org'
    #   port 6667
    # end
    #
    # bot.add_custom_pattern(:number, "[0-9]")
    #
    # bot.plugin("getnum :foo-number") do |m|
    #   m.reply "Your number was: #{m.args[:foo]}"
    # end
    def add_custom_pattern(name, pattern)
      @custom_patterns[name.to_s] = "(#{pattern.to_s})"
    end
    alias :add_custom_type :add_custom_pattern # backwards
    alias :add_pattern :add_custom_pattern

    # Run run run
    def run
      @irc.connect options.server, options.port
      @irc.pass options.password if options.password
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

      # runs on any symbol
      @listeners[:any].each { |l| l.call(message) } if @listeners.key?(:any)

      if @listeners.key?(message.symbol)
        @listeners[message.symbol].each {|l| l.call(message) }
      end

      if [:privmsg].include?(message.symbol)

        # At the moment we must traverse all possibly rules, which
        # could get clunky with a lot of rules. This is because each
        # rule can be unique in what prefix it uses, in future some kind
        # of loose checking should be put in place
        rules.each do |rule|
          unless rule.options.key?(:prefix) || options.prefix == false
            unless rule.to_s[1..options.prefix.size] == options.prefix
              rule.to_s.insert(1, options.prefix)
            end
          end

          if message.text && mdata = message.text.rstrip.match(Regexp.new(rule.to_s))
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
