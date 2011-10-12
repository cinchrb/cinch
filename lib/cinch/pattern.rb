# -*- coding: utf-8 -*-
module Cinch
  # @api private
  # @since 1.1.0
  class Pattern
    # @param [String, Regexp, NilClass, Proc, #to_s] obj The object to
    #   convert to a regexp
    # @return [Regexp, nil]
    def self.obj_to_r(obj)
      case obj
      when Regexp, NilClass
        return obj
      else
        return Regexp.new(Regexp.escape(obj.to_s))
      end
    end

    def self.resolve_proc(obj, msg = nil)
      if obj.is_a?(Proc)
        return resolve_proc(obj.call(msg), msg)
      else
        return obj
      end
    end

    attr_reader :prefix
    attr_reader :suffix
    attr_reader :pattern
    def initialize(prefix, pattern, suffix)
      @prefix, @pattern, @suffix = prefix, pattern, suffix
    end

    def to_r(msg = nil)
      prefix  = Pattern.obj_to_r(Pattern.resolve_proc(@prefix, msg))
      suffix  = Pattern.obj_to_r(Pattern.resolve_proc(@suffix, msg))
      pattern = Pattern.resolve_proc(@pattern, msg)

      case pattern
      when Regexp, NilClass
        /#{prefix}#{pattern}#{suffix}/
      else
        /^#{prefix}#{Pattern.obj_to_r(pattern)}#{suffix}$/
      end
    end
  end
end
