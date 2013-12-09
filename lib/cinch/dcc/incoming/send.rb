require "socket"
require "ipaddr"

module Cinch
  module DCC
    module Incoming
      # DCC SEND is a protocol for transferring files, usually found
      # in IRC. While the handshake, i.e. the details of the file
      # transfer, are transferred over IRC, the actual file transfer
      # happens directly between two clients. As such it doesn't put
      # stress on the IRC server.
      #
      # When someone tries to send a file to the bot, the `:dcc_send`
      # event will be triggered, in which the DCC request can be
      # inspected and optionally accepted.
      #
      # The event handler receives the plain message object as well as
      # an instance of this class. That instance contains information
      # about {#filename the suggested file name} (in a sanitized way)
      # and allows for checking the origin.
      #
      # It is advised to reject transfers that seem to originate from
      # a {#from_private_ip? private IP} or {#from_localhost? the
      # local IP itself} unless that is expected. Otherwise, specially
      # crafted requests could cause the bot to connect to internal
      # services.
      #
      # Finally, the file transfer can be {#accept accepted} and
      # written to any object that implements a `#<<` method, which
      # includes File objects as well as plain strings.
      #
      # @example Saving a transfer to a temporary file
      #   require "tempfile"
      #
      #   listen_to :dcc_send, method: :incoming_dcc
      #   def incoming_dcc(m, dcc)
      #     if dcc.from_private_ip? || dcc.from_localhost?
      #       @bot.loggers.debug "Not accepting potentially dangerous file transfer"
      #       return
      #     end
      #
      #     t = Tempfile.new(dcc.filename)
      #     dcc.accept(t)
      #     t.close
      #   end
      #
      # @attr_reader filename
      class Send
        # @private
        PRIVATE_NETS = [IPAddr.new("fc00::/7"),
                        IPAddr.new("10.0.0.0/8"),
                        IPAddr.new("172.16.0.0/12"),
                        IPAddr.new("192.168.0.0/16")]

        # @private
        LOCAL_NETS = [IPAddr.new("127.0.0.0/8"),
                      IPAddr.new("::1/128")]

        # @return [User]
        attr_reader :user

        # @return [Integer]
        attr_reader :size

        # @return [String]
        attr_reader :ip

        # @return [Fixnum]
        attr_reader :port

        # @param [Hash] opts
        # @option opts [User] user
        # @option opts [String] filename
        # @option opts [Integer] size
        # @option opts [String] ip
        # @option opts [Fixnum] port
        # @api private
        def initialize(opts)
          @user, @filename, @size, @ip, @port = opts.values_at(:user, :filename, :size, :ip, :port)
        end

        # @return [String] The basename of the file name, with
        #   (back)slashes removed.
        def filename
          File.basename(File.expand_path(@filename)).delete("/\\")
        end

        # This method is used for accepting a DCC SEND offer. It
        # expects an object to save the result to (usually an instance
        # of IO or String).
        #
        # @param [#<<] io The object to write the data to.
        # @return [Boolean] True if the transfer finished
        #   successfully, false otherwise.
        # @note This method blocks.
        # @example Saving to a file
        #   f = File.open("/tmp/foo", "w")
        #   dcc.accept(f)
        #   f.close
        #
        # @example Saving to a string
        #   s = ""
        #   dcc.accept(s)
        def accept(io)
          socket = TCPSocket.new(@ip, @port)
          total = 0

          while buf = socket.readpartial(8192)
            total += buf.bytesize

            begin
              socket.write_nonblock [total].pack("N")
            rescue Errno::EWOULDBLOCK, Errno::AGAIN
              # Nobody cares about ACKs, really. And if the sender
              # couldn't receive it at this point, they probably don't
              # care, either.
            end
            io << buf

            # Break here in case the sender doesn't close the
            # connection on the final ACK.
            break if total == @size
          end

          socket.close
          return true
        rescue EOFError
          return false
        end

        # @return [Boolean] True if the DCC originates from a private ip
        # @see #from_localhost?
        def from_private_ip?
          ip   = IPAddr.new(@ip)
          PRIVATE_NETS.any? {|n| n.include?(ip)}
        end

        # @return [Boolean] True if the DCC originates from localhost
        # @see #from_private_ip?
        def from_localhost?
          ip   = IPAddr.new(@ip)
          LOCAL_NETS.any? {|n| n.include?(ip)}
        end
      end
    end
  end
end
