module Cinch
  module Utilities
    # @since 2.0.0
    # @api private
    module Kernel
      # @return [Object]
      def self.string_to_const(s)
        return s unless s.is_a?(::String)
        s.split("::").inject(Kernel) {|base, name| base.const_get(name) }
      end
    end
  end
end
