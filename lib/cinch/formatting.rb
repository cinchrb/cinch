module Cinch
  # This module can be used for adding and removing colors and
  # formatting to/from messages.
  #
  # The format codes used are those defined by mIRC, which are also
  # the ones supported by most clients.
  #
  # For usage instructions and examples, see {.format}.
  #
  # List of valid colors
  # =========================
  # - aqua
  # - black
  # - blue
  # - brown
  # - green
  # - grey
  # - lime
  # - orange
  # - pink
  # - purple
  # - red
  # - royal
  # - silver
  # - teal
  # - white
  # - yellow
  #
  # List of valid attributes
  # ========================
  # - bold
  # - italic
  # - reverse/reversed
  # - underline/underlined
  #
  # Other
  # =====
  # - reset (Resets all formatting to the client's defaults)
  #
  # @since 2.0.0
  module Formatting
    # @private
    Colors = {
      :white  => "00",
      :black  => "01",
      :blue   => "02",
      :green  => "03",
      :red    => "04",
      :brown  => "05",
      :purple => "06",
      :orange => "07",
      :yellow => "08",
      :lime   => "09",
      :teal   => "10",
      :aqua   => "11",
      :royal  => "12",
      :pink   => "13",
      :grey   => "14",
      :silver => "15",
    }

    # @private
    Attributes = {
      :bold       => 2.chr,
      :underlined => 31.chr,
      :underline  => 31.chr,
      :reversed   => 22.chr,
      :reverse    => 22.chr,
      :italic     => 29.chr,
      :reset      => 15.chr,
    }

    # @param [Array<Symbol>] settings The colors and attributes to apply.
    #   When supplying two colors, the first will be used for the
    #   foreground and the second for the background.
    # @param [String] string The string to format.
    # @return [String] the formatted string
    # @since 2.0.0
    # @raise [ArgumentError] When passing more than two colors as arguments.
    # @see Helpers#Format Helpers#Format for easier access to this method.
    #
    # @example Nested formatting, combining text styles and colors
    #   reply = Format(:underline, "Hello %s! Is your favourite color %s?" % [Format(:bold, "stranger"), Format(:red, "red")])
    def self.format(*settings, string)
      string   = string.dup

      attributes = settings.select {|k| Attributes.has_key?(k)}.map {|k| Attributes[k]}
      colors = settings.select {|k| Colors.has_key?(k)}.map {|k| Colors[k]}
      if colors.size > 2
        raise ArgumentError, "At most two colors (foreground and background) might be specified"
      end

      attribute_string = attributes.join
      color_string = if colors.empty?
                       ""
                     else
                       "\x03#{colors.join(",")}"
                     end

      prepend = attribute_string + color_string
      append  = Attributes[:reset]

      # attributes act as toggles, so e.g. underline+underline = no
      # underline. We thus have to delete all duplicate attributes
      # from nested strings.
      string.delete!(attribute_string)

      # Replace the reset code of nested strings to continue the
      # formattings of the outer string.
      string.gsub!(/#{Attributes[:reset]}/, Attributes[:reset] + prepend)
      return prepend + string + append
    end

    # Deletes all mIRC formatting codes from the string. This strips
    # formatting for bold, underline and so on, as well as color
    # codes. This does include removing the numeric arguments.
    #
    # @param [String] string The string to filter
    # @return [String] The filtered string
    # @since 2.2.0
    def self.unformat(string)
      string.gsub(/[\x02\x0f\x16\x1f\x12]|\x03(\d{1,2}(,\d{1,2})?)?/, '')
    end
  end
end
