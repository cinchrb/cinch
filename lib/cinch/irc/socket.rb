module Cinch
  module IRC
    # == Author
    # * Lee Jarvis - ljjarvis@gmail.com
    #
    # == Description
    # This class has been directly take from the irc-socket library. Original documentation
    # for this class can be found {here}[http://rdoc.injekt.net/irc-socket].
    #
    # IRCSocket is an IRC wrapper around a TCPSocket. It implements all of the major 
    # commands laid out in {RFC 2812}[http://irchelp.org/irchelp/rfc/rfc2812.txt].
    # All these commands are available as instance methods of an IRCSocket Object.
    #
    # == Example
    #  irc = IRCSocket.new('irc.freenode.org')
    #  irc.connect
    #
    #  if irc.connected?
    #    irc.nick "HulkHogan"
    #    irc.user "Hulk", 0, "*", "I am Hulk Hogan"
    #
    #    while line = irc.read
    #         
    #      # Join a channel after MOTD
    #      if line.split[1] == '376'
    #        irc.join "#mychannel"
    #      end
    #
    #      puts "Received: #{line}"
    #    end
    #  end
    #
    # === Block Form
    #  IRCSocket.new('irc.freenode.org') do |irc|
    #    irc.nick "SpongeBob"
    #    irc.user "Spongey", 0, "*", "Square Pants"
    #
    #    puts irc.read
    #  end
    class Socket

      # The server our socket is connected to
      attr_reader :server

      # The port our socket is connected on
      attr_reader :port

      # The TCPSocket instance
      attr_reader :socket

      # Creates a new IRCSocket and automatically connects
      #
      # === Example
      #  irc = IRCSocket.open('irc.freenode.org')
      #
      #  while data = irc.read
      #    puts data
      #  end
      def self.open(server, port=6667)
        irc = new(server, port)
        irc.connect
        irc
      end
      
      # Create a new IRCSocket to connect to +server+ on +port+. Defaults to port 6667.
      # If an optional code block is given, it will be passed an instance of the IRCSocket.
      # NOTE: Using the block form does not mean the socket will send the applicable QUIT
      # command to leave the IRC server. You must send this yourself.
      def initialize(server, port=6667)
        @server = server
        @port = port

        @socket = nil
        @connected = false

        if block_given?
          connect
          yield self      
        end
      end
      
      # Check if our socket is alive and connected to an IRC server
      def connected?
        @connected
      end
      alias connected connected?
      
      # Connect to an IRC server, returns true on a successful connection, or
      # raises otherwise
      def connect
        @socket = TCPSocket.new(server, port)
      rescue Interrupt
        raise
      rescue Exception
        raise
      else
        @connected = true
      end

      # Read the next line in from the server. If no arguments are passed
      # the line will have the CRLF chomp'ed. Returns nil if no data could be read
      def read(chompstr="\r\n")
        if data = @socket.gets("\r\n")
          data.chomp!(chompstr) if chompstr
          data
        else
          nil
        end
      rescue IOError
        nil
      end

      # Write to our Socket and append CRLF
      def write(data)
        @socket.write(data + "\r\n")
      rescue IOError
        raise
      end

      # Sugar for #write
      def raw(*args) # :nodoc:
        args.last.insert(0, ':') unless args.last.nil?
        write args.join(' ').strip
      end

      # More sugar
      def write_optional(command, *optional) # :nodoc:
        command = "#{command} #{optional.join(' ')}" if optional
        write(command.strip)
      end
      private :raw, :write_optional

      # Send PASS command
      def pass(password)
        write("PASS #{password}")
      end

      # Send NICK command
      def nick(nickname)
        write("NICK #{nickname}")
      end

      # Send USER command 
      def user(user, mode, unused, realname)
        write("USER #{user} #{mode} #{unused} :#{realname}")
      end

      # Send OPER command
      def oper(name, password)
        write("OPER #{name} #{password}")
      end

      # Send the MODE command.
      # Should probably implement a better way of doing this
      def mode(channel, *modes)
        write("MODE #{channel} #{modes.join(' ')}")
      end

      # Send QUIT command
      def quit(message=nil)
        raw("QUIT", message)
      end

      # Send JOIN command - Join a channel with given password
      def join(channel, password=nil)
        write("JOIN #{channel}")
      end

      # Send PART command
      def part(channel, message=nil)
        raw("PART", channel, message)
      end

      # Send TOPIC command
      def topic(channel, topic=nil)
        raw("TOPIC", channel, topic)
      end

      # Send NAMES command
      def names(*channels)
        write("NAMES #{channels.join(',') unless channels.empty?}")
      end

      # Send LIST command
      def list(*channels)
        write("LIST #{channels.join(',') unless channels.empty?}")
      end

      # Send INVITE command
      def invite(nickname, channel)
        write("INVITE #{nickname} #{channel}")
      end

      # Send KICK command
      def kick(channel, user, comment=nil)
        raw("KICK", channel, user, comment)
      end

      # Send PRIVMSG command
      def privmsg(target, message)
        write("PRIVMSG #{target} :#{message}")
      end

      # Send NOTICE command
      def notice(target, message)
        write("NOTICE #{target} :#{message}")
      end

      # Send MOTD command
      def motd(target=nil)
        write_optional("MOTD", target)
      end

      # Send VERSION command
      def version(target=nil)
        write_optional("VERSION", target)
      end

      # Send STATS command
      def stats(*params)
        write_optional("STATS", params)
      end

      # Send TIME command
      def time(target=nil)
        write_optional("TIME", target)
      end

      # Send INFO command
      def info(target=nil)
        write_optional("INFO", target)
      end

      # Send SQUERY command
      def squery(target, message)
        write("SQUERY #{target} :#{message}")
      end

      # Send WHO command
      def who(*params)
        write_optional("WHO", params)
      end

      # Send WHOIS command
      def whois(*params)
        write_optional("WHOIS", params)
      end

      # Send WHOWAS command
      def whowas(*params)
        write_optional("WHOWAS", params)
      end

      # Send KILL command
      def kill(user, message)
        write("KILL #{user} :#{message}")
      end

      # Send PING command
      def ping(server)
        write("PING #{server}")
      end

      # Send PONG command
      def pong(server)
        write("PONG #{server}")
      end

      # Send AWAY command
      def away(message=nil)
        raw("AWAY", message)
      end

      # Send USERS command
      def users(target=nil)
        write_optional("USERS", target)
      end

      # Send USERHOST command
      def userhost(*users)
        write("USERHOST #{users.join(' ')}")
      end

      # Close our socket instance
      def close
        @socket.close if connected?
      end
    end
  end
end

