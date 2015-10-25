# -*- coding: utf-8 -*-
require "cinch/target"
require "timeout"

module Cinch
  # @attr_reader [String] authname
  # @attr_reader [String, nil] away The user's away message, or
  #   `nil` if not away.
  # @attr_reader [Array<Channel>] channels All channels the user is
  #   in.
  # @attr_reader [String] host
  # @attr_reader [Integer] idle How long this user has been idle, in seconds.
  #   This is a snapshot of the last WHOIS.
  # @attr_reader [String] nick The user's nickname
  # @attr_reader [Boolean] online True if the user is online.
  # @attr_reader [Boolean] oper True if the user is an IRC operator.
  # @attr_reader [String] realname
  # @attr_reader [Boolean] secure True if the user is using a secure
  #   connection, i.e. SSL.
  # @attr_reader [Time] signed_on_at
  # @attr_reader [Boolean] unknown True if the instance references an user who
  #   cannot be found on the server.
  # @attr_reader [String] user
  #
  # @version 2.0.0
  class User < Target
    include Syncable

    def nick
      name
    end

    # @return [String]
    # @since 1.1.0
    attr_reader :last_nick

    # @return [Boolean]
    attr_reader :synced
    # @since 2.1.0
    alias_method :synced?, :synced

    # @return [Boolean]
    # @api private
    attr_accessor :in_whois

    def user
      attr(:user, true, false)
    end

    def host
      attr(:host, true, false)
    end

    def realname
      attr(:realname, true, false)
    end

    def authname
      attr(:authname, true, false)
    end

    def away
      attr(:away, true, false)
    end

    def idle
      attr(:idle, true, false)
    end

    def signed_on_at
      attr(:signed_on_at, true, false)
    end

    def unknown
      attr(:unknown?, true, false)
    end
    alias_method :unknown?, :unknown

    # @note This attribute will be updated by various events, but
    # unless {#monitor} is being used, this information cannot be
    # ensured to be always correct.
    def online
      attr(:online?, true, false)
    end
    alias_method :online?, :online

    def channels
      attr(:channels, true, false)
    end

    def secure
      attr(:secure?, true, false)
    end
    alias_method :secure?, :secure

    # @since 2.1.0
    def oper
      attr(:oper?, true, false)
    end
    alias_method :oper?, :oper

    # @private
    def user_unsynced
      attr(:user, true, true)
    end

    # @private
    def host_unsynced
      attr(:host, true, true)
    end

    # @private
    def realname_unsynced
      attr(:realname, true, true)
    end

    # @private
    def authname_unynced
      attr(:authname, true, true)
    end

    # @private
    def idle_unsynced
      attr(:idle, true, true)
    end

    # @private
    def signed_on_at_unsynced
      attr(:signed_on_at, true, true)
    end

    # @private
    def unknown_unsynced
      attr(:unknown?, true, true)
    end
    alias_method "unknown?_unsynced", "unknown_unsynced"

    # @private
    def online_unsynced
      attr(:online?, true, true)
    end
    alias_method "online?_unsynced", "online_unsynced"

    # @private
    def channels_unsynced
      attr(:channels, true, true)
    end

    # @private
    def secure_unsynced
      attr(:secure?, true, true)
    end
    alias_method "secure?_unsynced", "secure_unsynced"

    # @private
    # @since 2.1.0
    def oper_unsynced
      attr(:oper?, true, true)
    end
    alias_method "oper?_unsynced", "oper_unsynced"

    # By default, you can use methods like {#user}, {#host} and
    # alike – If you however fear that another thread might change
    # data while you're using it and if this means a critical issue to
    # your code, you can store a clone of the result of this method
    # and work with that instead.
    #
    # @example
    #   on :channel do |m|
    #     data = m.user.data.dup
    #     do_something_with(data.user)
    #     do_something_with(data.host)
    #   end
    # @return [Hash]
    attr_reader :data

    # @return [Boolean] True if the user is being monitored
    # @see #monitor
    # @see #unmonitor
    # @note The attribute writer is in fact part of the private API
    attr_reader :monitored
    # @since 2.1.0
    alias_method :monitored?, :monitored

    # @api private
    attr_writer :monitored

    # @note Generally, you shouldn't initialize new instances of this
    #   class. Use {UserList#find_ensured} instead.
    def initialize(*args)
      @data = {
        :user         => nil,
        :host         => nil,
        :realname     => nil,
        :authname     => nil,
        :idle         => 0,
        :signed_on_at => nil,
        :unknown?     => false,
        :online?      => false,
        :channels     => [],
        :secure?      => false,
        :away         => nil,
        :oper?        => false,
      }
      case args.size
      when 2
        @name, @bot = args
      when 4
        @data[:user], @name, @data[:host], @bot = args
      else
        raise ArgumentError
      end

      @synced_attributes  = Set.new

      @when_requesting_synced_attribute = lambda {|attr|
        unless attribute_synced?(attr)
          @data[:unknown?] = false
          unsync :unknown?

          refresh
        end
      }

      @monitored = false
    end

    # Checks if the user is identified. Currently officially supports
    # Quakenet and Freenode.
    #
    # @return [Boolean] true if the user is identified
    # @version 1.1.0
    def authed?
      !attr(:authname).nil?
    end

    # @see Syncable#attr
    def attr(attribute, data = true, unsync = false)
      super
    end

    # Queries the IRC server for information on the user. This will
    # set the User's state to not synced. After all information are
    # received, the object will be set back to synced.
    #
    # @return [void]
    # @note The alias `whois` is deprecated and will be removed in a
    #   future version.
    def refresh
      return if @in_whois
      @data.keys.each do |attr|
        unsync attr
      end

      @in_whois = true
      if @bot.irc.network.whois_only_one_argument?
        @bot.irc.send "WHOIS #@name"
      else
        @bot.irc.send "WHOIS #@name #@name"
      end
    end
    alias_method :whois, :refresh # deprecated
    undef_method(:whois) # yardoc hack

    # @deprecated
    def whois
      Cinch::Utilities::Deprecation.print_deprecation("2.2.0", "User#whois", "User#refresh")
      refresh
    end

    # @param [Hash, nil] values A hash of values gathered from WHOIS,
    #   or `nil` if no data was returned
    # @return [void]
    # @api private
    # @since 1.0.1
    def end_of_whois(values)
      @in_whois = false
      if values.nil?
        # for some reason, we did not receive user information. one
        # reason is freenode throttling WHOIS
        Thread.new do
          sleep 2
          refresh
        end
        return
      end

      if values[:unknown?]
        sync(:unknown?, true, true)
        self.online = false
        sync(:idle, 0, true)
        sync(:channels, [], true)

        fields = @data.keys
        fields.delete(:unknown?)
        fields.delete(:idle)
        fields.delete(:channels)
        fields.each do |field|
          sync(field, nil, true)
        end

        return
      end

      if values[:registered]
        values[:authname] ||= self.nick
        values.delete(:registered)
      end
      {
        :authname => nil,
        :idle     => 0,
        :secure?  => false,
        :oper?    => false,
        :away     => nil,
        :channels => [],
      }.merge(values).each do |attr, value|
        sync(attr, value, true)
      end

      sync(:unknown?, false, true)
      self.online = true
    end

    # @return [void]
    # @since 1.0.1
    # @api private
    # @see Syncable#unsync_all
    def unsync_all
      super
    end

    # @return [String]
    def to_s
      @name
    end

    # @return [String]
    def inspect
      "#<User nick=#{@name.inspect}>"
    end

    # Generates a mask for the user.
    #
    # @param [String] s a pattern for generating the mask.
    #
    #     - %n = nickname
    #     - %u = username
    #     - %h = host
    #     - %r = realname
    #     - %a = authname
    #
    # @return [Mask]
    def mask(s = "%n!%u@%h")
      s = s.gsub(/%(.)/) {
        case $1
        when "n"
          @name
        when "u"
          self.user
        when "h"
          self.host
        when "r"
          self.realname
        when "a"
          self.authname
        end
      }

      Mask.new(s)
    end

    # Check if the user matches a mask.
    #
    # @param [Ban, Mask, User, String] other The user or mask to match against
    # @return [Boolean]
    def match(other)
      Mask.from(other) =~ Mask.from(self)
    end
    alias_method :=~, :match

    # Starts monitoring a user's online state by either using MONITOR
    # or periodically running WHOIS.
    #
    # @since 2.0.0
    # @return [void]
    # @see #unmonitor
    def monitor
      if @bot.irc.isupport["MONITOR"] > 0
        @bot.irc.send "MONITOR + #@name"
      else
        refresh
        @monitored_timer = Timer.new(@bot, interval: 30) {
          refresh
        }
        @monitored_timer.start
      end

      @monitored = true
    end

    # Stops monitoring a user's online state.
    #
    # @since 2.0.0
    # @return [void]
    # @see #monitor
    def unmonitor
      if @bot.irc.isupport["MONITOR"] > 0
        @bot.irc.send "MONITOR - #@name"
      else
        @monitored_timer.stop if @monitored_timer
      end

      @monitored = false
    end

    # Send data via DCC SEND to a user.
    #
    # @param [DCC::DCCableObject] io
    # @param [String] filename
    # @since 2.0.0
    # @return [void]
    # @note This method blocks.
    def dcc_send(io, filename = File.basename(io.path))
      own_ip = bot.config.dcc.own_ip || @bot.irc.socket.addr[2]
      dcc = DCC::Outgoing::Send.new(receiver: self,
                                    filename: filename,
                                    io: io,
                                    own_ip: own_ip
                                    )

      dcc.start_server

      handler = Handler.new(@bot, :message,
                            Pattern.new(/^/,
                                        /\001DCC RESUME #{filename} #{dcc.port} (\d+)\001/,
                                        /$/)) do |m, position|
        next unless m.user == self
        dcc.seek(position.to_i)
        m.user.send "\001DCC ACCEPT #{filename} #{dcc.port} #{position}\001"

        handler.unregister
      end
      @bot.handlers.register(handler)

      @bot.loggers.info "DCC: Outgoing DCC SEND: File name: %s - Size: %dB - IP: %s - Port: %d - Status: waiting" % [filename, io.size, own_ip, dcc.port]
      dcc.send_handshake
      begin
        dcc.listen
        @bot.loggers.info "DCC: Outgoing DCC SEND: File name: %s - Size: %dB - IP: %s - Port: %d - Status: done" % [filename, io.size, own_ip, dcc.port]
      rescue Timeout::Error
        @bot.loggers.info "DCC: Outgoing DCC SEND: File name: %s - Size: %dB - IP: %s - Port: %d - Status: failed (timeout)" % [filename, io.size, own_ip, dcc.port]
      ensure
        handler.unregister
      end
    end

    # Updates the user's online state and dispatch the correct event.
    #
    # @since 2.0.0
    # @return [void]
    # @api private
    def online=(bool)
      notify = self.__send__("online?_unsynced") != bool && @monitored
      sync(:online?, bool, true)

      return unless notify
      if bool
        @bot.handlers.dispatch(:online, nil, self)
      else
        @bot.handlers.dispatch(:offline, nil, self)
      end
    end

    # Used to update the user's nick on nickchange events.
    #
    # @param [String] new_nick The user's new nick
    # @api private
    # @return [void]
    def update_nick(new_nick)
      @last_nick, @name = @name, new_nick
      # Unsync authname because some networks tie authentication to
      # the nick, so the user might not be authenticated anymore after
      # changing their nick
      unsync(:authname)
      @bot.user_list.update_nick(self)
    end
  end
end
