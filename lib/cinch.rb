require 'cinch/bot'

module Cinch
  VERSION = '1.1.3'

  # @return [Object]
  # @api private
  def self.string_to_const(s)
    return s unless s.is_a?(String)
    s.split("::").inject(Kernel) {|base, name| base.const_get(name) }
  end

  # @return [String]
  # @todo Handle mIRC color codes more gracefully.
  # @api private
  def self.filter_string(string)
    string.gsub(/[\x00-\x1f]/, '')
  end

  # @api private
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

  # @api private
  def self.encode_outgoing(string, encoding)
    string = string.dup
    if encoding == :irc
      # If your text contains only characters that fit inside the CP1252
      # code page (aka Windows Latin-1), the entire line will be sent
      # that way. mIRC users should see it correctly. XChat users who
      # are using UTF-8 will also see it correctly, because it will fail
      # UTF-8 validation and will be assumed to be CP1252, even by older
      # XChat versions.
      #
      # If the text doesn't fit inside the CP1252 code page, (for eaxmple if you
      # type Eastern European characters, or Russian) it will be sent as UTF-8. Only
      # UTF-8 capable clients will be able to see these characters correctly
      #
      # (from http://xchat.org/encoding/#hybrid)
      begin
        string.encode!("CP1252")
      rescue Encoding::UndefinedConversionError
      end
    else
      string.encode!(encoding, {:invalid => :replace, :undef => :replace})
    end

    return string
  end
end
