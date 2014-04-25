module Cinch
  module Utilities
    # @since 2.0.0
    # @api private
    module Deprecation
      def self.print_deprecation(version, method)
        $stderr.puts "Deprecation warning: Beginning with version #{version}, #{method} should not be used anymore."
        $stderr.puts caller
      end
    end
  end
end
