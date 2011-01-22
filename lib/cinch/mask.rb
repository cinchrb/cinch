module Cinch
  class Mask
    # @return [String]
    attr_reader :nick
    # @return [String]
    attr_reader :user
    # @return [String]
    attr_reader :host
    # @return [String]
    attr_reader :mask
    def initialize(mask)
      @mask = mask
      @nick, @user, @host = mask.match(/(.+)!(.+)@(.+)/)[1..-1]
      @regexp = Regexp.new("^" + Regexp.escape(mask).gsub("\\*", ".*") + "$")
    end

    # @return [Boolean]
    def ==(other)
      other.respond_to?(:mask) && other.mask == @mask
    end

    # @return [Boolean]
    def eql?(other)
      other.is_a?(self.class) && self == other
    end

    def hash
      @mask.hash
    end

    # @param [Ban, Mask, User, String] target
    # @return [Boolean]
    def match(target)
      return self.class.from(target).mask =~ @regexp

      # TODO support CIDR (freenode)
    end
    alias_method :=~, :match

    # @return [String]
    def to_s
      @mask.dup
    end

    # @param [Ban, Mask, User, String]
    # @return [Mask]
    def self.from(target)
      case target
      when User, Ban
        target.mask
      when String
        Mask.new(target)
      when Mask
        target
      else
        raise ArgumentError
      end
    end
  end
end
