module Cinch
  class Pattern
    def self.obj_to_r(obj, str_start_anchor = true, str_end_anchor = true)
      return obj if obj.is_a?(Regexp)
      return obj_to_r(obj.call, str_start_anchor, str_end_anchor) if obj.is_a?(Proc)
      return /#{str_start_anchor ? "^" : ""}#{Regexp.escape(obj.to_s)}#{str_end_anchor ? "$" : ""}/
    end

    attr_reader :prefix
    attr_reader :pattern
    def initialize(prefix, pattern)
      @prefix, @pattern = prefix, pattern
    end

    def to_r
      prefix = Pattern.obj_to_r(@prefix, true, false)
      pattern = Pattern.obj_to_r(@pattern)

      /#{prefix}#{pattern}/
    end
  end
end
