# -*- coding: utf-8 -*-
module Cinch
  # @api private
  # @since 1.1.0
  class Pattern
    # @param [String, Regexp, NilClass, Proc, #to_s] obj The object to
    #   convert to a regexp
    # @return [Regexp, nil]
    def self.obj_to_r(obj, anchor = nil)
      case obj
      when Regexp, NilClass
        return obj
      else
        escaped = Regexp.escape(obj.to_s)
        case anchor
        when :start
          return Regexp.new("^" + escaped)
        when :end
          return Regexp.new(escaped + "$")
        when nil
          return Regexp.new(Regexp.escape(obj.to_s))
        end
      end
    end

    def self.resolve_proc(obj, msg = nil)
      if obj.is_a?(Proc)
        return resolve_proc(obj.call(msg), msg)
      else
        return obj
      end
    end

    def self.generate(type, argument)
      case type
      when :ctcp
        Pattern.new(/^/, /#{Regexp.escape(argument.to_s)}(?:$| .+)/, nil)
      else
        raise ArgumentError, "Unsupported type: #{type.inspect}"
      end
    end

    attr_reader :prefix
    attr_reader :suffix
    attr_reader :pattern
    def initialize(prefix, pattern, suffix)
      @prefix, @pattern, @suffix = prefix, pattern, suffix
    end

    def to_r(msg = nil)
      pattern = Pattern.resolve_proc(@pattern, msg)

      case pattern
      when Regexp, NilClass
        prefix  = Pattern.obj_to_r(Pattern.resolve_proc(@prefix, msg), :start)
        suffix  = Pattern.obj_to_r(Pattern.resolve_proc(@suffix, msg), :end)
        /#{prefix}#{pattern}#{suffix}/
      else
        prefix  = Pattern.obj_to_r(Pattern.resolve_proc(@prefix, msg))
        suffix  = Pattern.obj_to_r(Pattern.resolve_proc(@suffix, msg))
        /^#{prefix}#{Pattern.obj_to_r(pattern)}#{suffix}$/
      end
    end
  end
end
