module Cinch
  module Utilities
    module Kernel
      # @return [Object]
      # @api private
      def self.string_to_const(s)
        return s unless s.is_a?(String)
        s.split("::").inject(Kernel) {|base, name| base.const_get(name) }
      end
    end
  end
end
