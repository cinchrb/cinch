module Cinch
  # @since 1.2.0
  module Formatting
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

    Attributes = {
      :bold       => 2.chr,
      :underlined => 31.chr,
      :reversed   => 22.chr,
      :italic     => 22.chr,
      :reset      => 15.chr,
    }

    def self.format(*args)
      settings = args[0..-2]
      string     = args.last

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

      string = string.gsub(/#{Attributes[:reset]}/, Attributes[:reset] + prepend)
      return prepend + string + append
    end
  end
end
