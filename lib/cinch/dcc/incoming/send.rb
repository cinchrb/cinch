require "socket"
require "ipaddr"

module Cinch
  # @since 2.0.0
  module DCC
    module Incoming
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

        # @return [String]
        attr_reader :filename

        # @return [Number]
        attr_reader :size

        # @return [String]
        attr_reader :ip

        # @return [Number]
        attr_reader :port

        # @param [Hash] opts
        # @option opts [User] user
        # @option opts [String] filename
        # @option opts [Number] size
        # @option opts [String] ip
        # @option opts [Number] port
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
        # @return [void]
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
          while buf = socket.read(1024)
            total += buf.bytesize

            socket.write [total].pack("N")
            io << buf
          end
        end

        # @return [Boolean] True if the DCC originates from a private ip
        def from_private_ip?
          ip   = IPAddr.new(@ip)
          PRIVATE_NETS.any? {|n| n.include?(ip)}
        end

        # @return [Boolean] True if the DCC originates from localhost
        def from_localhost?
          ip   = IPAddr.new(@ip)
          LOCAL_NETS.any? {|n| n.include?(ip)}
        end
      end
    end
  end
end
