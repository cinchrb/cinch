module Cinch
  module Encryption
    class Blowcrypt
      module Base64
        Alphabet = "./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze

        def self.encode(data)
          res = ""
          data = data.dup.force_encoding("BINARY")

          data.chars.each_slice(8) do |slice|
            slice = slice.join
            left, right = slice.unpack('L>L>')
            6.times do
              res << Alphabet[right & 0x3f]
              right >>= 6
            end

            6.times do
              res << Alphabet[left & 0x3f]
              left >>= 6
            end
          end

          return res
        end

        def self.decode(data)
          res = ""
          data = data.dup.force_encoding("BINARY")
          data.chars.each_slice(12) do |slice|
            slice = slice.join
            left = right = 0

            slice[0..5].each_char.with_index do |p, i|
              right |= Alphabet.index(p) << (i * 6)
            end

            slice[6..11].each_char.with_index do |p, i|
              left |= Alphabet.index(p) << (i * 6)
            end

            res << [left, right].pack('L>L>')
          end

          return res
        end
      end

      def self.valid?(s)
        s.start_with?("+OK ")
      end

      def initialize(key)
        @key = key
      end

      def encrypt(data)
        data      = pad(data, 8)
        cipher    = generate_cipher(:encrypt)
        encrypted = cipher.update(data) << cipher.final

        return "+OK " + Base64.encode(encrypted)
      end

      def decrypt(data)
        data      = data[4..-1]
        cipher    = generate_cipher(:decrypt)
        decrypted = cipher.update(Base64.decode(data)) << cipher.final

        return decrypted.gsub(/\0+$/, '')
      end

      private
      def generate_cipher(mode)
        cipher = OpenSSL::Cipher.new("BF-ECB")
        cipher.__send__(mode)

        cipher.padding = 0
        cipher.key_len = @key.bytesize
        cipher.key     = @key

        cipher
      end

      def pad(s, to)
        length = s.bytesize
        if length % to != 0
          s = s + ("\0" * (to - length % to))
        end

        return s
      end
    end
  end
end
