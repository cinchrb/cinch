require "cinch/exceptions"

module Cinch
  # @api private
  # @since 1.1.0
  module ModeParser
    ErrEmptyString = "Empty mode string"
    MalformedError = Struct.new(:modes)
    EmptySequenceError = Struct.new(:modes)
    NotEnoughParametersError = Struct.new(:op)
    TooManyParametersError = Struct.new(:modes, :params)

    # @param [String] modes The mode string as sent by the server
    # @param [Array<String>] params Parameters belonging to the modes
    # @param [Hash{:add, :remove => Array<String>}] param_modes
    #   A mapping describing which modes require parameters
    # @return [(Array<(Symbol<:add, :remove>, String<char>, String<param>), foo)]
    def self.parse_modes(modes, params, param_modes = {})
      if modes.size == 0
        return nil, ErrEmptyString
        # raise Exceptions::InvalidModeString, 'Empty mode string'
      end

      if modes[0] !~ /[+-]/
        return nil, MalformedError.new(modes)
        # raise Exceptions::InvalidModeString, "Malformed modes string: %s" % modes
      end

      changes = []

      direction = nil
      count = -1

      modes.each_char do |ch|
        if ch =~ /[+-]/
          if count == 0
            return changes, EmptySequenceError.new(modes)
            # raise Exceptions::InvalidModeString, 'Empty mode sequence: %s' % modes
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
          if param_modes.has_key?(direction) && param_modes[direction].include?(ch)
            if params.size > 0
              param = params.shift
            else
              return changes, NotEnoughParametersError.new(ch)
              # raise Exceptions::InvalidModeString, 'Not enough parameters: %s' % ch.inspect
            end
          end
          changes << [direction, ch, param]
          count += 1
        end
      end

      if params.size > 0
        return changes, TooManyParametersError.new(modes, params)
        # raise Exceptions::InvalidModeString, 'Too many parameters: %s %s' % [modes, params]
      end

      if count == 0
        return changes, EmptySequenceError.new(modes)
        # raise Exceptions::InvalidModeString, 'Empty mode sequence: %s' % modes
      end

      return changes, nil
    end
  end
end
