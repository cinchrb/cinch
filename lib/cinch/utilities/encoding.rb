module Cinch
  module Utilities
    # @since 2.0.0
    # @api private
    module Encoding
      def self.encode_incoming(string, encoding)
        string = string.dup
        if encoding == :irc
          # If incoming text is valid UTF-8, it will be interpreted as
          # such. If it fails validation, a CP1252 -&gt; UTF-8 conversion
          # is performed. This allows you to see non-ASCII from mIRC
          # users (non-UTF-8) and other users sending you UTF-8.
          #
          # (from http://xchat.org/encoding/#hybrid)
          string.force_encoding("UTF-8")
          if !string.valid_encoding?
            string.force_encoding("CP1252").encode!("UTF-8", {:invalid => :replace, :undef => :replace})
          end
        else
          string.force_encoding(encoding).encode!({:invalid => :replace, :undef => :replace})
          string = string.chars.select { |c| c.valid_encoding? }.join
        end

        return string
      end

      def self.encode_outgoing(string, encoding)
        string = string.dup
        if encoding == :irc
          encoding = "UTF-8"
        end

        return string.encode!(encoding, {:invalid => :replace, :undef => :replace}).force_encoding("ASCII-8BIT")
      end
    end
  end
end
