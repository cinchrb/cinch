module Cinch
  module IRC
    
    # == Author
    # * Lee Jarvis - ljjarvis@gmail.com
    #
    # == Description
    # IRC::Message is a nicely encapsulated IRC message object. Used directly by 
    # IRC::Parser#parse_servermessage and sent to every plugin defined. It does
    # not do any parsing of itself, that's all down to the parser
    #
    # == See
    # * Cinch::IRC::Parser#parse_servermessage
    #
    # TODO: Add more documentation
    class Message

      # Message prefix
      attr_reader :prefix

      # Message command (PRIVMSG, JOIN, KICK, etc)
      attr_reader :command

      # Message params
      attr_reader :params

      # Message symbol (lowercase command, ie. :privmsg, :join, :kick)
      attr_reader :symbol
      
      # The raw string passed to ::new
      attr_reader :raw

      # Hash with message attributes
      attr_reader :data

      # Message text
      attr_reader :text

      # Arguments parsed from a rule
      attr_accessor :args

      # The IRC::Socket object (or nil)
      attr_accessor :irc

      # Invoked directly from IRC::Parser#parse_servermessage
      def initialize(raw, prefix, command, params)
        @raw = raw
        @prefix = prefix
        @command = command
        @params = params
        @text = params.last unless params.empty?

        @symbol = command.downcase.to_sym
        @data = {}
        @args = {}
        @irc = nil
      end

      # Access attribute
      def [](var)
        @data[var.to_sym]
      end

      # Add a new attribute (stored in @data)
      def add(var, val)
        @data[var.to_sym] = val
      end
      alias []= add

      # Remove an attribute
      def delete(var)
        var = var.to_sym
        return unless @data.key?(var)
        @data.delete(var)
      end

      # Alter an attribute
      def alter(var, val)
        if @data.key?(var)
          @data[var] = val
        end
      end

      # Check if our message was sent privately
      def private?
        !@data[:channel]
      end

      # Add the nick/user/host attributes
      def apply_user(nick, user, host)
        @data[:nick] = nick
        @data[:user] = user
        @data[:host] = host
      end

      # Reply to a channel or user, probably the most commonly used helper
      # method
      def reply(text)
        recipient = data[:channel] || data[:nick]
        @irc.privmsg(recipient, text)
      end

      # Same as reply but prefixes the users nickname
      def answer(text)
        return unless data[:channel]
        @irc.privmsg(data[:channel], "#{data[:nick]}: #{text}")
      end

      # The deadly /me action
      def action(text)
        reply("\001ACTION #{text}\001")
      end

      # The raw IRC message
      def to_s
        raw
      end

      # Catch methods and check if they exist as keys in
      # the attribute hash
      def method_missing(meth, *args, &blk) # :nodoc:
        if @data.key?(meth)
          @data[meth]
        else
          nil
        end
      end

    end
  end
end

