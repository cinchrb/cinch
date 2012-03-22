require "socket"
require "ipaddr"
require "timeout"

module Cinch
  module DCC
    module Outgoing
      # DCC SEND is a protocol for transferring files, usually found
      # in IRC. While the handshake, i.e. the details of the file
      # transfer, are transferred over IRC, the actual file transfer
      # happens directly between two clients. As such it doesn't put
      # stress on the IRC server.
      #
      # Cinch allows sending files by either using
      # {Cinch::User#dcc_send}, which takes care of all parameters as
      # well as setting up resume support, or by creating instances of
      # this class directly. The latter will only be useful to people
      # working on the Cinch code itself.
      #
      # {Cinch::User#dcc_send} expects an object to send as well as
      # optionaly a file name, which is sent to the receiver as a
      # suggestion where to save the file. If no file name is
      # provided, the method will use the object's `#path` method to
      # determine it.
      #
      # Any object that implements {DCC::DCCableObject} can be sent,
      # but sending files will probably be the most common case.
      #
      # If you're behind a NAT it is necessary to explicitly set the
      # external IP using the {file:docs/bot_options.md#dccownip dcc.own_ip
      # option}.
      #
      # @example Sending a file to a user
      #   match "send me something"
      #   def execute(m)
      #     m.user.dcc_send(open("/tmp/cookies"))
      #   end
      class Send
        # @param [Hash] opts
        # @option opts [User] receiver
        # @option opts [String] filename
        # @option opts [File] io
        # @option opts [String] own_ip
        def initialize(opts = {})
          @receiver, @filename, @io, @own_ip = opts.values_at(:receiver, :filename, :io, :own_ip)
        end

        # Start the server
        #
        # @return [void]
        def start_server
          @socket = TCPServer.new(0)
          @socket.listen(1)
        end

        # Send the handshake to the user.
        #
        # @return [void]
        def send_handshake
          handshake = "\001DCC SEND %s %d %d %d\001" % [@filename, IPAddr.new(@own_ip).to_i, port, @io.size]
          @receiver.send(handshake)
        end

        # Listen for an incoming connection.
        #
        # This starts listening for an incoming connection to the server
        # started by {#start_server}. After a client successfully
        # connected, the server socket will be closed and the file
        # transferred to the client.
        #
        # @raise [Timeout::Error] Raised if the receiver did not connect
        #   within 30 seconds
        # @return [void]
        # @note This method blocks.
        def listen
          begin
            fd = nil
            Timeout.timeout(30) do
              fd, _ = @socket.accept
              send_data(fd)
              fd.close
            end
          ensure
            @socket.close
          end
        end

        # Seek to `pos` in the data.
        #
        # @param [Integer] pos
        # @return [void]
        # @api private
        def seek(pos)
          @io.seek(pos)
        end

        # @return [Fixnum] The port used for the socket
        def port
          @port ||= @socket.addr[1]
        end

        private
        def send_data(fd)
          @io.advise(:sequential)

          while chunk = @io.read(8096)
            rs, ws = IO.select([fd], [fd])
            rs.first.recv         unless rs.empty?
            ws.first.write(chunk) unless ws.empty?
          end
        end
      end
    end
  end
end
