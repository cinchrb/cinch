# Extensions to Ruby's String class.
class String
  # Like `String#downcase`, but respecting different IRC casemaps.
  #
  # @param [:rfc1459, :"strict-rfc1459", :ascii] mapping
  # @return [String]
  def irc_downcase(mapping)
    case mapping
    when :rfc1459
      self.tr("A-Z[]\\\\^", "a-z{}|~")
    when :"strict-rfc1459"
      self.tr("A-Z[]\\\\", "a-z{}|")
    else
      # when :ascii or unknown/nil
      self.tr("A-Z", "a-z")
    end
  end

  # Like `String#upcase`, but respecting different IRC casemaps.
  #
  # @param [:rfc1459, :"strict-rfc1459", :ascii] mapping
  # @return [String]
  def irc_upcase(mapping)
    case mapping
    when :ascii
      self.tr("a-z", "A-Z")
    when :rfc1459
      self.tr("a-z{}|~", "A-Z[]\\\\^")
    when :"strict-rfc1459"
      self.tr("a-z{}|", "A-Z[]\\\\")
    end
  end
end
