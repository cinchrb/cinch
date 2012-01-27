module Cinch
  # This class allows querying the IRC server for its name and certain
  # non-standard behaviour.
  class IRCd
    # @return [Symbol]
    attr_reader :name

    # @param [Symbol] name
    def initialize(name)
      @name = name
    end

    # @return [String, nil] The mode used for getting the list of
    #   channel owners, if any
    def owner_list_mode
      return "q" if @name == :unreal
    end

    # @return [String, nil] The mode used for getting the list of
    #   channel quiets, if any
    def quiet_list_mode
      return "q" if @name == :"ircd-seven"
    end

    # @return [Boolean] Does WHOIS only support one argument?
    def whois_only_one_argument?
      @name == :jtv
    end

    # @return [Boolean] True if connected to NgameTV
    def ngametv?
      @name == :ngametv
    end

    # @return [Boolean] True if connected to JTV
    def jtv?
      @name == :jtv
    end

    # @return [Boolean] True if we do not know which network we are
    #   connected to.
    def unknown?
      @name == :unknown
    end
  end
end
