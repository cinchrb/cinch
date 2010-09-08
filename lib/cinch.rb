require 'cinch/bot'

module Cinch
  VERSION = '1.0.2'

  # @return [String]
  # @todo Handle mIRC color codes more gracefully.
  # @api private
  def self.filter_string(string)
    string.gsub(/[\x00-\x1f]/, '')
  end
end
