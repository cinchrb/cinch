module Cinch
  class IRCd
    attr_reader :name
    def initialize(name)
      @name = name
    end

    def owner_list_mode
      return "q" if @name == :unreal
    end

    def quiet_list_mode
      return "q" if @name == :"ircd-seven"
    end

    def whois_only_one_argument?
      @name == :jtv
    end

    def ngametv?
      @name == :ngametv
    end

    def jtv?
      @name == :jtv
    end

    def unknown?
      @name == :unknown
    end
  end
end
