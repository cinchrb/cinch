module Cinch
  # This class represents masks, which are primarily used for bans.
  class Mask
    # @return [String]
    attr_reader :nick
    # @return [String]
    attr_reader :user
    # @return [String]
    attr_reader :host
    # @return [String]
    attr_reader :mask

    # @version 1.1.2
    # @param [String] mask
    def initialize(mask)
      @mask = mask
      @nick, @user, @host = mask.match(/(.+)!(.+)@(.+)/)[1..-1]
      @regexp = Regexp.new("^" + Regexp.escape(mask).gsub("\\*", ".*").gsub("\\?", ".?") + "$")
    end

    # @return [Boolean]
    # @since 1.1.0
    def ==(other)
      other.respond_to?(:mask) && other.mask == @mask
    end

    # @return [Boolean]
    # @since 1.1.0
    def eql?(other)
      other.is_a?(self.class) && self == other
    end

    # @return [Fixnum]
    def hash
      @mask.hash
    end

    # @param [Mask, String, #mask] target
    # @return [Boolean]
    # @version 1.1.2
    def match(target)
      return self.class.from(target).mask =~ @regexp

      # TODO support CIDR (freenode)
    end
    alias_method :=~, :match

    # @return [String]
    def to_s
      @mask.dup
    end

    # @param [String, #mask] target
    # @return [target] if already a Mask
    # @return [Mask]
    # @version 2.0.0
    def self.from(target)
      return target if target.is_a?(self)

      if target.respond_to?(:mask)
        mask = target.mask
      else
        mask = Mask.new(target.to_s)
      end

      return mask
    end
  end
end
