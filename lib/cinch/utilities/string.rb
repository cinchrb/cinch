# -*- coding: utf-8 -*-
module Cinch
  module Utilities
    # @since 2.0.0
    module String
      # Deletes all characters in the range 0–31 as well as the
      # character 127, that is all non-printable characters, newlines
      # and tab stops.
      #
      # This method is useful for filtering text from external sources
      # before sending it to IRC.
      #
      # Note that this method does not gracefully handle mIRC color
      # codes, because it will leave the numeric arguments behind. If
      # your text comes from IRC, you may want to filter it through
      # {strip_colors} first. If you want to send sanitized input that
      # includes your own formatting, first use this method, then add
      # your formatting.
      #
      # There exist methods for sending messages that automatically
      # call this method, namely {Target#safe_msg},
      # {Target#safe_notice}, and {Target#safe_action}.
      #
      # @param [String] string The string to filter
      # @return [String] The filtered string
      def self.filter_string(string)
        string.gsub(/[\x00-\x1f\x7f]/, '')
      end

      # Deletes all mIRC formatting codes from the string. This strips
      # formatting for bold, underline and so on, as well as color
      # codes. This does include removing the numeric arguments.
      #
      # @param [String] string The string to filter
      # @return [String] The filtered string
      def self.strip_colors(string)
        string.gsub(/[\x02\x0f\x16\x1f\x12]|\x03(\d{1,2}(,\d{1,2})?)?/, '')
      end
    end
  end
end
