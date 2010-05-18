module Cinch
  module IRC

    # == Author
    # * Lee Jarvis - ljjarvis@gmail.com
    #
    # == Description
    # Parse incoming IRC lines and extract data, returning a nicely
    # encapsulated Cinch::IRC::Message
    #
    # == Example
    #  require 'cinch/irc/parser'
    #  include Cinch::IRC::Parser
    #
    #  message = parse(":foo!bar@myhost.com PRIVMSG #mychan :ding dong!")
    #
    #  message.class #=> Cinch::IRC::Message
    #  message.command #=> PRIVMSG
    #  message.nick #=> foo
    #  message.channel #=> #mychan
    #  message.text #=> ding dong!
    class Parser

      # A hash holding all of our patterns
      attr_reader :patterns

      def initialize
        @patterns = {}
        setup_patterns
      end

      # Add a new pattern
      def add_pattern(key, pattern)
        raise ArgumentError, "Pattern is not a regular expression" unless pattern.is_a?(Regexp)
        @patterns[key.to_sym] = pattern
      end

      # Remove a pattern
      def remove_pattern(key)
        key = key.to_sym
        @patterns.delete(key) if @patterns.key?(key)
      end

      # Helper for our patterns Hash
      def pattern(key)
        @patterns[key]
      end

      # Set up some default patterns used directly by this class
      def setup_patterns
        add_pattern :letter, /[a-zA-Z]/
          add_pattern :hex, /[\dA-Fa-f]/

          add_pattern :ip4addr, /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
          add_pattern :ip6addr, /[\dA-Fa-f](?::[\dA-Fa-f]){7}|0:0:0:0:0:(?:0|[Ff]{4}):#{pattern(:ip4addr)}/
          add_pattern :hostaddr, /#{pattern(:ip4addr)}|#{pattern(:ip6addr)}/
          add_pattern :shortname, /[A-Za-z0-9][A-Za-z0-9-]*/
          add_pattern :hostname, /#{pattern(:shortname)}(?:\.#{pattern(:shortname)})*/
          add_pattern :host, /#{pattern(:hostname)}|#{pattern(:hostaddr)}/

          add_pattern :user, /[^\x00\x10\x0D\x20@]+/
          add_pattern :nick, /[A-Za-z\[\]\\`_^{|}][A-Za-z\d\[\]\\`_^{|}-]{0,19}/

          add_pattern :userhost, /(#{pattern(:nick)})(?:(?:!(#{pattern(:user)}))?@(#{pattern(:host)}))?/

          add_pattern :channel, /(?:[#+&]|![A-Z\d]{5})[^\x00\x07\x10\x0D\x20,:]/

          # Server message parsing patterns
          add_pattern :prefix, /(?:(\S+)\x20)?/
          add_pattern :command, /([A-Za-z]+|\d{3})/
          add_pattern :middle, /[^\x00\x20\r\n:][^\x00\x20\r\n]*/
          add_pattern :trailing, /[^\x00\r\n]*/
          add_pattern :params, /(?:((?:#{pattern(:middle)}){0,14}(?::?#{pattern(:trailing)})?))/
          add_pattern :message, /\A#{pattern(:prefix)}#{pattern(:command)}#{pattern(:params)}\Z/

          add_pattern :params_scan, /(?!:)([^\x00\x20\r\n:]+)|:([^\x00\r\n]*)/
      end
      private :setup_patterns

      # Parse the incoming raw IRC string and return
      # a nicely formatted IRC::Message
      def parse_servermessage(raw)
        raise ArgumentError, raw unless raw && matches = raw.match(pattern(:message))

        prefix, command, parameters = matches.captures

        params = []
        parameters.scan(pattern(:params_scan)) {|a, c| params << (a || c) }

        m = IRC::Message.new(raw, prefix, command, params)

        if prefix && userhost = parse_userhost(prefix)
          nick, user, host = userhost.captures
          m.add(:nick, nick)
          m.add(:user, user)
          m.add(:host, host)

          unless m.params.empty?
            m.add(:recipient, m.params.first)
            m.add(:channel, m.recipient) if valid_channel?(m.recipient)
          end
        end

        m # Return our IRC::Message
      end
      alias :parse :parse_servermessage

      # Parse the prefix returned from the server
      # and return an Array of [nick, user, host] or 
      # nil if no match is found
      def parse_userhost(prefix)
        if matches = prefix.match(pattern(:userhost))
          matches.captures
        else
          nil
        end
      end
      alias :extract_userhost :parse_userhost

      # Check if a string is a valid channel
      def valid_channel?(str)
        !str.match(pattern(:channel)).nil?
      end

    end
  end
end

