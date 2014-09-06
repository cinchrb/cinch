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
          # CP1252 encoding is compatible with ISO-8859-1 encoding. The
          # reason for choice of it instead of ISO-8859-1 is that some
          # IRC clients may send CP1252 messages. Cinch will never send them,
          # but it's possible that others will actually do.
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
          # If your text contains only characters that fit inside the ISO-8859-1
          # code page (aka Latin1), the entire line will be sent that way. mIRC
          # users should see it correctly. XChat users who are using UTF-8 will
          # also see it correctly, because it will fail UTF-8 validation and will
          # be assumed to be ISO-8859-1, even by older XChat versions.
          #
          # If the text doesn't fit inside the ISO-8859-1 code page, (for example if you
          # type Eastern European characters, or Russian) it will be sent as UTF-8. Only
          # UTF-8 capable clients will be able to see these characters correctly
          #
          # (from http://xchat.org/encoding/#hybrid)
          begin
            string.encode!("ISO-8859-1")
          rescue ::Encoding::UndefinedConversionError
          end
        else
          string.encode!(encoding, {:invalid => :replace, :undef => :replace}).force_encoding("ASCII-8BIT")
        end

        return string
      end
    end
  end
end
