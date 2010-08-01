require 'newton/bot'

module Newton
  # @todo Handle mIRC color codes more gracefully.
  # @api private
  def self.filter_string(string)
    s.gsub(/[\x00-\x1f]/)
  end
end
