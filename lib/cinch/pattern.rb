# -*- coding: utf-8 -*-
module Cinch
  class Pattern
    def self.obj_to_r(obj, msg = nil, str_end_anchor = true)
      case obj
      when Regexp, NilClass
        return obj
      when Proc
        return obj_to_r(obj.call(msg), msg, str_end_anchor)
      else
        return /#{Regexp.escape(obj.to_s)}#{str_end_anchor ? "$" : ""}/
      end
    end

    attr_reader :prefix
    attr_reader :pattern
    def initialize(prefix, pattern)
      @prefix, @pattern = prefix, pattern
    end

    def to_r(msg = nil)
      prefix = Pattern.obj_to_r(@prefix, msg, true, false)
      end_anchor   = @pattern.is_a?(String) # important

      pattern = Pattern.obj_to_r(@pattern, msg, end_anchor)
      r = /#{prefix}#{pattern}/
      p r
      r
    end
  end
end

# [x] on·regexp = regexp [prefix=nil, pattern=regexp]
# [x] plugin·regexp·no_prefix = regexp [prefix=nil, pattern=regexp]
# [x] on·string = ^string$ [prefix=/^/, pattern=string]
# [x] plugin·string·no_prefix = ^string$
# [x] plugin·regexp·prefix = prefix + regexp [prefix=prefix, pattern=regexp] ← really?
# [x] plugin·string·prefix = prefix + string + $ [prefix=prefix, pattern=string]
