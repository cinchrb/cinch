require "socket"
require "ipaddr"
require "timeout"

module Cinch
  # @since 2.0.0
  module DCC
    module Outgoing
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
        # started by {start_server}. After a client successfully
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
        # @param [Number] pos
        # @return [void]
        # @api private
        def seek(pos)
          @io.seek(pos)
        end

        # @return [Number] The port used for the socket
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
