module Cinch
  # @since 2.0.0
  # @api private
  module Utilities
    module String
      # @return [String]
      # @todo Handle mIRC color codes more gracefully.
      def self.filter_string(string)
        string.gsub(/[\x00-\x1f]/, '')
      end
    end
  end
end
