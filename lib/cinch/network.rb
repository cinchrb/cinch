module Cinch
  # This class allows querying the IRC network for its name and used
  # server software as well as certain non-standard behaviour.
  #
  # @since 2.0.0
  class Network
    # @return [Symbol] The name of the network. `:unknown` if the
    #   network couldn't be detected.
    attr_reader :name

    # @api private
    attr_writer :name

    # @return [Symbol] The server software used by the network.
    #   `:unknown` if the software couldn't be detected.
    attr_reader :ircd

    # @api private
    attr_writer :ircd

    # @return [Array<Symbol>] All client capabilities supported by the
    # network.
    attr_reader :capabilities

    # @api private
    attr_writer :capabilities

    # @param [Symbol] name
    # @param [Symbol] ircd
    # @api private
    # @note The user should not create instances of this class but use
    #   {IRC#network} instead.
    def initialize(name, ircd)
      @name         = name
      @ircd         = ircd
      @capabilities = []
    end

    # @return [String, nil] The mode used for getting the list of
    #   channel owners, if any
    def owner_list_mode
      return "q" if @ircd == :unreal || @ircd == :inspircd
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

    # @return [Numeric] The `messages per second` value that best suits
    #   the current network
    def default_messages_per_second
      case @name
      when :freenode
        0.7
      else
        0.5
      end
    end

    # @return [Integer] The `server queue size` value that best suits
    #   the current network
    def default_server_queue_size
      case @name
      when :quakenet
        40
      else
        10
      end
    end
  end
end
