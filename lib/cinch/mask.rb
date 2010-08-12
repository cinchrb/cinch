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
      @regexp = Regexp.new(Regexp.escape(mask).gsub("\\*", ".*"))
    end

    # @return [Boolean]
    def match(user)
      mask = "%s!%s@%s" % [nick, user, host]
      return mask =~ @regexp

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
