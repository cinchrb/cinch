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

      def self.strip_colors(string)
        string.gsub(/[\x02\x0f\x16\x1f\x12]|\x03(\d{1,2}(,\d{1,2})?)?/, '')
      end
    end
  end
end
