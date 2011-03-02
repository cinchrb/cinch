module Cinch
  # @since 1.2.0
  class Handler < Struct.new(:event, :pattern, :args, :block); end
end
