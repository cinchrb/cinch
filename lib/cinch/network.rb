module Cinch
  # This class allows querying the IRC server for its name and certain
  # non-standard behaviour.
  class Network
    # @return [Symbol]
    attr_reader :name

    # @return [Symbol]
    attr_reader :ircd

    # @param [Symbol] name
    def initialize(name, ircd)
      @name = name
      @ircd = ircd
    end

    # @return [String, nil] The mode used for getting the list of
    #   channel owners, if any
    def owner_list_mode
      return "q" if @ircd == :unreal
    end

    # @return [String, nil] The mode used for getting the list of
    #   channel quiets, if any
    def quiet_list_mode
      return "q" if @ircd == :"ircd-seven"
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
    #   connected to
    def unknown_network?
      @name == :unknown
    end

    # @return [Boolean] True if we do not know which software the
    #   server is running
    def unknown_ircd?
      @ircd == :unknown
    end

    # Note for the default_* methods: Always make sure to return a
    # value for when no network/ircd was detected so that MessageQueue
    # doesn't break.

    
    def default_messages_per_second
      case @network
      when :freenode
        0.7
      else
        0.5
      end
    end

    def default_server_queue_size
      case @network
      when :quakenet
        40
      else
        10
      end
    end
  end
end
