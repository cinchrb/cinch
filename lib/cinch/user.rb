# -*- coding: utf-8 -*-
module Cinch
  class User
    include Syncable

    @users = {}
    class << self

      # @overload find_ensured(nick, bot)
      #   Finds or creates a user based on his nick.
      #
      #   @param [String] nick The user's nickname
      #   @param [Bot]    bot  An instance of Bot
      # @overload find_ensured(user, nick, host, bot)
      #   Finds or creates a user based on his nick but already
      #   setting user and host.
      #
      #   @param [String] user The username
      #   @param [String] nick The nickname
      #   @param [String] host The user's hostname
      #   @param [Bot]    bot  An instance of bot
      #
      # @return [User]
      def find_ensured(*args)
        # FIXME CASEMAPPING
        case args.size
        when 2
          nick = args.first
          bargs = [args.first]
          bot  = args.last
        when 4
          nick = args[1]
          bot = args.pop
          bargs = args
        else
          raise ArgumentError
        end
        downcased_nick = nick.irc_downcase(bot.irc.isupport["CASEMAPPING"])
        @users[downcased_nick] ||= new(*bargs, bot)
        @users[downcased_nick]
      end

      # Finds a user.
      #
      # @param [String] nick nick of a user
      # @return [User, nil]
      def find(nick)
        @users[nick]
      end

      # @return [Array<User>] Returns all users
      def all
        @users.values
      end
    end


    # @return [String]
    attr_reader :nick
    # @return [Bot]
    attr_reader :bot
    # @return [Boolean]
    attr_reader :synced
    # @return [Boolean]
    attr_reader :in_whois

    # @return [String]
    attr_reader :user
    undef_method "user"

    # @return [String]
    attr_reader :host
    undef_method "host"

    # @return [String]
    attr_reader :realname
    undef_method "realname"

    # @return [String]
    attr_reader :authname
    undef_method "authname"

    attr_reader :registered
    undef_method "registered"

    # @return [Number] How long this user has been idle, in seconds.
    #   This is a snapshot of the last WHOIS.
    attr_reader :idle
    undef_method "idle"

    # @return [Time]
    attr_reader :signed_on_at
    undef_method "signed_on_at"

    # @return [Boolean] True if the instance references an user who
    #   cannot be found on the server.
    attr_reader :unknown
    alias_method :unknown?, :unknown
    undef_method "unknown?"
    undef_method "unknown"
    def unknown
      self.unknown?
    end

    # @return [Array<Channel>] All channels the user is in.
    attr_reader :channels
    undef_method "channels"

    # @return [Boolean] True if the user is using a secure connection, i.e. SSL.
    attr_reader :secure
    alias_method :secure?, :secure
    undef_method "secure?"
    undef_method "secure"
    def secure
      self.secure?
    end

    # By default, you can use methods like User#user, User#host and
    # alike – If you however fear that another thread might change
    # data while you're using it and if this means a critical issue to
    # your code, you can store the result of this method and work with
    # that instead.
    #
    # @example
    #   on :channel do
    #     data = user.data
    #     do_something_with(data.user)
    #     do_something_with(data.host)
    #   end
    # @return [Hash]
    attr_reader :data
    def initialize(*args)
      @data = {
        :user         => nil,
        :host         => nil,
        :realname     => nil,
        :authname     => nil,
        :idle         => 0,
        :signed_on_at => nil,
        :unknown?     => false,
        :channels     => [],
        :secure?      => false,
        :registered   => false,
      }
      case args.size
      when 2
        @nick, @bot = args
      when 4
        @data[:user], @nick, @data[:host], @bot = args
      else
        raise ArgumentError
      end

      @synced_attributes  = Set.new

      @when_requesting_synced_attribute = lambda {|attr|
        unless @synced
          @data[:unknown?] = false
          unsync :unknown?

          unsync attr
          whois
        end
      }
    end

    # Checks if the user is identified. Currently officially supports
    # Quakenet and Freenode.
    #
    # @return [Boolean] true if the user is identified
    def authed?
      @data[:authname]
    end

    # Checks if the user is an identified and registerd user.
    # Used by Unreal-IRCd
    #
    # @return [Boolean] true if the user is registered
    def registered?
      @data[:registered]
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
    def whois
      return if @in_whois
      @synced = false
      @data.keys.each do |attr|
        unsync attr
      end

      @in_whois = true
      @bot.raw "WHOIS #@nick #@nick"
    end
    alias_method :refresh, :whois

    # @param [Hash, nil] values A hash of values gathered from WHOIS,
    #   or `nil` if no data was returned
    # @param [Boolean] not_found Has to be true if WHOIS resulted in
    #   an unknown user
    # @return [void]
    # @api private
    def end_of_whois(values, not_found = false)
      @in_whois = false
      if not_found
        sync(:unknown?, true, true)
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

      if values.nil?
        # for some reason, we did not receive user information. one
        # reason is freenode throttling WHOIS
        Thread.new do
          sleep 2
          whois
        end
        return
      end

      {
        :authname => nil,
        :idle => 0,
        :secure? => false,
        :registered => false,
      }.merge(values).each do |attr, value|
        sync(attr, value, true)
      end

      sync(:unknown?, false, true)
      @synced = true
    end

    # @api private
    def unsync_all
      @synced = false
      super
    end

    # Send a message to the user.
    #
    # @param [String] message the message
    # @return [void]
    def send(message)
      @bot.msg(@nick, message)
    end
    alias_method :privmsg, :send
    alias_method :msg, :send

    # Send a message to the user, but remove any non-printable
    # characters. The purpose of this method is to send text from
    # untrusted sources, like other users or feeds.
    #
    # Note: this will **break** any mIRC color codes embedded in the
    # string.
    #
    # @param (see #send)
    # @return (see #send)
    # @see #send
    # @see Bot#safe_msg
    # @todo Handle mIRC color codes more gracefully.
    def safe_send(message)
      @bot.safe_msg(@nick, message)
    end
    alias_method :safe_privmsg, :safe_send
    alias_method :safe_msg, :safe_send

    # Send a CTCP to the user.
    #
    # @param [String] message the ctcp message
    # @return [void]
    def ctcp(message)
      send "\001#{message}\001"
    end

    # Send an action (/me) to the user.
    #
    # @param [String] message the message
    # @return [void]
    # @see #safe_action
    def action(message)
      @bot.action(@name, message)
    end

    # Send an action (/me) to the user but remove any non-printable
    # characters. The purpose of this method is to send text from
    # untrusted sources, like other users or feeds.
    #
    # Note: this will **break** any mIRC color codes embedded in the
    # string.
    #
    # @param (see #action)
    # @return (see #action)
    # @see #action
    # @see Bot#safe_action
    # @todo Handle mIRC color codes more gracefully.
    def safe_action(message)
      @bot.safe_action(@name, message)
    end

    # @return [String]
    def to_s
      @nick
    end

    # @return [String]
    def inspect
      "#<User nick=#{@nick.inspect}>"
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
          @nick
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

    # Provides synced access to user attributes.
    def method_missing(m, *args)
      if m.to_s =~ /^(.+)_unsynced$/
        m = $1.to_sym
        unsync = true
      end

      if @data.has_key?(m)
        attr(m, true, unsync = false)
      else
        super
      end
    end

    # @return [Boolean]
    def ==(other)
      return case other
             when self.class
               @nick == other.nick
             when String
               self.to_s == other
             when Bot
               self.nick == other.config.nick
             else
               false
             end
    end
    alias_method :eql?, "=="

    # @return [Fixnum]
    def hash
      @nick.hash
    end
  end
end
