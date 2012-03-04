module Cinch
  module DCC
    # This module describes the required interface for objects that should
    # be sendable via DCC.
    #
    # @note `File` conforms to this interface.
    # @since 2.0.0
    # @abstract
    module DCCableObject
      # Return the next `number` bytes of the object.
      #
      # @param [Integer] number Read `number` bytes at most
      # @return [String] The read data
      # @return [nil] If no more data can be read
      def read(number)
      end

      # Seek to a specific position.
      #
      # @param [Integer] position The position in bytes to seek to
      # @return [void]
      def seek(position)
      end

      # @return [String] A string representing the object's path or name.
      #
      # @note This is only required if calling {User#dcc_send} with only
      #   one argument
      def path
      end

      # @return [Integer] The total size of the data, in bytes.
      def size
      end
    end
  end
end
