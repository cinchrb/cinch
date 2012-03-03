module Cinch
  module SASL
    class DiffieHellman
      attr_reader :p, :g, :q, :x, :e

      def initialize(p, g, q)
        @p = p
        @g = g
        @q = q
      end

      def generate(tries = 16)
        tries.times do
          @x = rand(@q)
          @e = mod_exp(@g, @x, @p)
          return @e if valid?
        end
        raise ArgumentError, "can't generate valid e"
      end

      # compute the shared secret, given the public key
      def secret(f)
        mod_exp(f, @x, @p)
      end

      private
      # validate a public key
      def valid?
        @e && @e.between?(2, @p - 2) && bits_set(@e) > 1
      end

      def bits_set(e)
        ("%b" % e).count('1')
      end

      def mod_exp(b, e, m)
        result = 1
        while e > 0
          result = (result * b) % m if e[0] == 1
          e = e >> 1
          b = (b * b) % m
        end
        return result
      end
    end
  end
end
