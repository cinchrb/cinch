module Cinch

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
  #
  # == Author
  # * Lee Jarvis - ljjarvis@gmail.com
  class Base

    # A Hash holding rules and attributes
    attr_reader :rules

    # A Hash holding listeners and reply Procs
    attr_reader :listeners

    # An OpenStruct holding all configuration options
    attr_reader :options

    # Our IRC::Socket instance
    attr_reader :irc

    # Default options hash
    DEFAULTS = {
      :port => 6667,
      :nick => "Cinch",
      :nick_suffix => '_',
      :username => 'cinch',
      :realname => "Cinch IRC Bot Building Framework",
      :prefix => '!',
      :usermode => 0,
      :password => nil,
      :ssl => false,
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
      @listeners[:ctcp] = {}

      @irc = IRC::Socket.new(options[:server], options[:port], options[:ssl])
      @parser = IRC::Parser.new

      # Default listeners
      on(:ping) {|m| @irc.pong(m.text) }

      on(:ctcp, :version) {|m| m.ctcp_reply "Cinch IRC Bot Building Framework v#{Cinch::VERSION}"}
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
    alias :rule :plugin

    # Add new listeners
    #
    # == Example
    #  on(376) do |m|
    #    m.join "#mychan"
    #  end
    #
    # This method also provides an alternative way to define a rule.
    # The following are equivalent
    #   plugin("foo bar") do |m|
    #     m.reply "baz!"
    #   end
    #
    #   on(:message, "foo bar") do |m|
    #     m.reply "baz!"
    #   end
    # 
    # This also gives us the opportunity to reply to CTCP messages
    #  on(:ctcp, :time) do |m|
    #    m.ctcp_reply Time.now.asctime
    #  end
    #
    # Note that when adding listeners for numberic IRC replies which
    # begin with a 0 (digit), make sure you define the command as a
    # String and not Integer. This is because 001.to_s == "1" so the
    # command will not work as expected.
    def on(*commands, &blk)
      if commands.first == :message
        rule, options = commands[1..2]
        options = {} unless options.is_a?(Hash)
        plugin(rule, options, &blk)
      elsif commands.first == :ctcp
        action = commands[1]

        if @listeners[:ctcp].key?(action)
          @listeners[:ctcp][action] << blk
        else
          @listeners[:ctcp][action] = [blk]
        end
      else
        commands.map {|x| x.to_s.downcase.to_sym }.each do |cmd|
          if @listeners.key?(cmd)
            @listeners[cmd] << blk
          else
            @listeners[cmd] = [blk]
          end
        end
      end
    end

    # This method builds a regular expression from your rule
    # and defines all named parameters, as well as dealing with
    # patterns.
    #
    # All patterns which exist in Cinch::IRC::Parser are supported
    #
    # == Examples
    # === Capturing digits
    #  bot.plugin("say :text-digit")
    # * Does match !say 3
    # * Does not match !say 3 4
    # * Does not match !say foo
    #
    # === Both digit and word
    #  bot.plugin("say :n-digit :text-word")
    # * Does match !say 3 foo
    # * Does not match !say 3 foo bar
    #
    # === Capturing until the end of the line
    #  bot.plugin("say :text")
    # * Does match !say foo
    # * Does match !say foo bar
    #
    # === Or mix them all
    #  bot.plugin("say :n-digit :who-word :text")
    #
    # Using "!say 3 injekt some text here" would provide
    # the following attributes
    # * m.args[:n] => 3
    # * m.args[:who] => injekt
    # * m.args[:text] => some text here
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
          if k =~ /\-\w+$/
            key, type = k.split('-')
            keys << key[1..-1]
            
            if @parser.has_pattern?(type)
              "(#{@parser.pattern(type)})"
            else
              "([^\x00\r\n]+?)"
            end
          else
            keys << k[1..-1]
            "([^\x00\r\n]+?)"
          end
        end
      end
      ["^#{pattern}$", keys]
    end

    # Add a custom pattern for rule validation
    #
    # == Example
    #  bot = Cinch.setup do
    #    server 'irc.freenode.org'
    #    port 6667
    #  end
    #
    #  bot.add_pattern(:number, /[0-9]/)
    #
    #  bot.plugin("getnum :foo-number") do |m|
    #    m.reply "Your number was: #{m.args[:foo]}"
    #  end
    def add_pattern(name, pattern)
      @parser.add_pattern(name, pattern)
    end
    alias :add_custom_pattern :add_pattern

    # Run run run
    def run
      # Configure some runtime listeners
      on(433) do |m|
        @options.nick += @options.nick_suffix
        @irc.nick @options.nick
      end

      if @options.respond_to?(:channels)
        on("004") { @options.channels.each {|c| @irc.join(c) } }
      end

      @irc.connect options.server, options.port
      @irc.pass options.password if options.password
      @irc.nick options.nick
      @irc.user options.username, options.usermode, '*', options.realname

      begin
        process(@irc.read) while @irc.connected?
      rescue Interrupt
        @irc.quit("Interrupted")
        puts "\nInterrupted. Shutting down .."
        exit
      end
    end
    alias :start :run

    private

    # Process the next line read from the server
    def process(line)
      return unless line
      message = @parser.parse(line)
      message.irc = @irc unless message.irc
      puts message if options.verbose

      # runs on any symbol
      @listeners[:any].each { |l| l.call(message) } if @listeners.key?(:any)

      if @listeners.key?(message.symbol)
        if message.symbol == :ctcp
          action = message.ctcp_action.downcase.to_sym

          if @listeners[:ctcp].include?(action)
            @listeners[:ctcp][action].each {|l| l.call(message) }
          end
        else
          @listeners[message.symbol].each {|l| l.call(message) }
        end
      end

      if [:privmsg].include?(message.symbol)
        rules.each do |rule|
          pattern = rule.to_s
          rule.keys.map! {|key| key.to_sym }
          prefix = nil
          
          if options.prefix
            if rule.options.key?(:prefix)
              if [:bot, :botnick, options.nick].include? rule.options[:prefix]
                prefix = options.nick + "[:,] "
              else              
                prefix = rule.options[:prefix]
              end
            else
              if [:bot, :botnick, options.nick].include? options.prefix
                prefix = options.nick + "[:,] "
              else
                prefix = options.prefix
              end
            end
          end
          
          # insert prefix unless it already exists
          pattern.insert(1, prefix) unless pattern[1..prefix.size] == prefix

          if rule.options[:ignore_case]
            regex = Regexp.new(pattern, Regexp::IGNORECASE)
          else
            regex = Regexp.new(pattern)
          end

          if message.text && mdata = message.text.rstrip.match(regex)
            unless rule.keys.empty? || mdata.captures.empty?
              args = Hash[rule.keys.zip(mdata.captures)]
              message.args = args
            end
            # execute rule
            rule.execute(message)
          end
        end
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
            op.on("--ssl") {|v| options[:ssl] = true }
            op.on("-C", "--channels x,y,z", Array, "Autojoin channels") {|v|
              options[:channels] = v.map {|c| %w(# + &).include?(c[0].chr) ? c : c.insert(0, '#') }
            }
          end.parse(ARGV)
        rescue OptionParser::MissingArgument => err
          warn "Missing values for options: #{err.args.join(', ')}\nFalling back to default"
        rescue OptionParser::InvalidOption => err
          warn err.message
        end
      end
      options
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
