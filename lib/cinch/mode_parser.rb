module Cinch
  module ModeParser
    def self.parse_modes(modes, params, param_modes = {})
      if modes.size == 0
        raise RuntimeError, 'Empty mode string'
      end

      if modes[0] !~ /[+-]/
        raise RuntimeError, "Malformed modes string: %s" % modes
      end

      # changes = {:add => [], :remove => []}
      changes = []

      direction = nil
      count = -1

      modes.each_char do |ch|
        if ch =~ /[+-]/
          if count == 0
            raise RuntimeError, 'Empty mode sequence: %s' % modes
          end

          direction = case ch
                      when "+"
                        :add
                      when "-"
                        :remove
                      end
          count = 0
        else
          param = nil
          if param_modes[direction].include?(ch)
            begin
              param = params.shift
            rescue IndexError
              raise RuntimeError, 'Not enough parameters: %r' % ch
            end
          end
          changes << [direction, ch, param]
          count += 1
        end
      end

      if params.size > 0
        raise RuntimeError, 'Too many parameters: %s %s' % [modes, params]
      end

      if count == 0
        raise RuntimeError, 'Empty mode sequence: %r' % modes
      end

      return changes
    end
  end
end
