module Cinch
  module Utilities
    module Deprecation
      # @api private
      def self.print_deprecation(version, method)
        $stderr.puts "Deprecation warning: Beginning with version #{version}, #{method} should not be used anymore."
        $stderr.puts caller
      end
    end
  end
end
