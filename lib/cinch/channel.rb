# -*- coding: utf-8 -*-
require "set"
require "cinch/target"

module Cinch
  # @attr limit
  # @attr secret
  # @attr moderated
  # @attr invite_only
  # @attr key
  class Channel < Target
    include Syncable
    include Helpers
    @channels = {}

    class << self
      # Finds or creates a channel.
      #
      # @param [String] name name of a channel
      # @param [Bot] bot a bot
      # @return [Channel]
      # @see Bot#Channel
      # @deprecated See {Bot#channel_manager} and {ChannelManager#find_ensured} instead
      # @note This method does not work properly if running more than one bot
      # @note This method will be removed in Cinch 2.0.0
      def find_ensured(name, bot)
        Cinch::Utilities::Deprecation.print_deprecation("1.1.0", "Channel.find_ensured")

        downcased_name = name.irc_downcase(bot.irc.isupport["CASEMAPPING"])
        @channels[downcased_name] ||= bot.channel_manager.find_ensured(name)
      end

      # Finds a channel.
      #
      # @param [String] name name of a channel
      # @return [Channel, nil]
      # @deprecated See {Bot#channel_manager} and {ChannelManager#find} instead
      # @note This method does not work properly if running more than one bot
      # @note This method will be removed in Cinch 2.0.0
      def find(name)
        Cinch::Utilities::Deprecation.print_deprecation("1.1.0", "Channel.find")

        @channels[name]
      end

      # @return [Array<Channel>] Returns all channels
      # @deprecated See {Bot#channel_manager} and {CacheManager#each} instead
      # @note This method does not work properly if running more than one bot
      # @note This method will be removed in Cinch 2.0.0
      def all
        Cinch::Utilities::Deprecation.print_deprecation("1.1.0", "User.all")

        @channels.values
      end
    end

    # @return [Array<User>] all users in the channel
    attr_reader :users
    synced_attr_reader :users

    # @return [String] the channel's topic
    attr_accessor :topic
    synced_attr_reader :topic

    # @return [Array<Ban>] all active bans
    attr_reader :bans
    synced_attr_reader :bans

    # @return [Hash<String => Object>]
    attr_reader :modes
    synced_attr_reader :modes
    def initialize(name, bot)
      @bot   = bot
      @name  = name
      @users = Hash.new {|h,k| h[k] = []}
      @bans  = []

      @modes = {}
      # TODO raise if not a channel

      @topic = nil

      @in_channel = false

      @synced_attributes  = Set.new
      @when_requesting_synced_attribute = lambda {|attr|
        unless @in_channel
          unsync(attr)
          case attr
          when :users
            @bot.raw "NAMES #@name"
          when :topic
            @bot.raw "TOPIC #@name"
          when :bans
            @bot.raw "MODE #@name +b"
          when :modes
            @bot.raw "MODE #@name"
          end
        end
      }
    end

    # @group Checks

    # @param [User, String] user An {User}-object or a nickname
    # @return [Boolean] Check if a user is in the channel
    def has_user?(user)
      @users.has_key?(User(user))
    end


    # @return [Boolean] true if `user` is opped in the channel
    def opped?(user)
      @users[User(user)].include? "o"
    end

    # @return [Boolean] true if `user` is half-opped in the channel
    def half_opped?(user)
      @users[User(user)].include? "h"
    end

    # @return [Boolean] true if `user` is voiced in the channel
    def voiced?(user)
      @users[User(user)].include? "v"
    end

    # @endgroup

    # @group User groups
    # @return [Array<User>] All ops in the channel
    def ops
      @users.select {|user, modes| modes.include?("o")}.keys
    end

    # @return [Array<User>] All half-ops in the channel
    def half_ops
      @users.select {|user, modes| modes.include?("h")}.keys
    end

    # @return [Array<User>] All voiced users in the channel
    def voiced
      @users.select {|user, modes| modes.include?("v")}.keys
    end

    # @return [Array<User>] All admins in the channel
    def admins
      @users.select {|user, modes| modes.include?("o")}.keys
    end
    # @endgroup

    # @return [Number] The maximum number of allowed users in the
    #   channel. 0 if unlimited.
    def limit
      @modes["l"].to_i
    end

    def limit=(val)
      if val == -1 or val.nil?
        mode "-l"
      else
        mode "+l #{val}"
      end
    end

    # @return [Boolean] true if the channel is secret (+s)
    def secret
      @modes["s"]
    end
    alias_method :secret?, :secret

    def secret=(bool)
      if bool
        mode "+s"
      else
        mode "-s"
      end
    end

    # @return [Boolean] true if the channel is moderated (only users
    #   with +o and +v are able to send messages)
    def moderated
      @modes["m"]
    end
    alias_method :moderated?, :moderated

    def moderated=(bool)
      if bool
        mode "+m"
      else
        mode "-m"
      end
    end

    # @return [Boolean] true if the channel is invite only (+i)
    def invite_only
      @modes["i"]
    end
    alias_method :invite_only?, :invite_only

    def invite_only=(bool)
      if bool
        mode "+i"
      else
        mode "-i"
      end
    end

    # @return [String, nil] The channel's key (aka password)
    def key
      @modes["k"]
    end

    def key=(new_key)
      if new_key.nil?
        mode "-k #{key}"
      else
        mode "+k #{new_key}"
      end
    end

    # @api private
    # @return [void]
    def sync_modes(all = true)
      unsync :users
      unsync :bans
      unsync :modes
      @bot.raw "NAMES #@name" if all
      @bot.raw "MODE #@name +b" # bans
      @bot.raw "MODE #@name"
    end

    # @group Channel Manipulation

    # Bans someone from the channel.
    #
    # @param [Ban, Mask, User, String] target the mask to ban
    # @return [Mask] the mask used for banning
    def ban(target)
      mask = Mask.from(target)

      @bot.raw "MODE #@name +b #{mask}"
      mask
    end

    # Unbans someone from the channel.
    #
    # @param [Ban, Mask, User, String] target the mask to unban
    # @return [Mask] the mask used for unbanning
    def unban(target)
      mask = Mask.from(target)

      @bot.raw "MODE #@name -b #{mask}"
      mask
    end

    # @param [String, User] user the user to op
    # @return [void]
    def op(user)
      @bot.raw "MODE #@name +o #{user}"
    end

    # @param [String, User] user the user to deop
    # @return [void]
    def deop(user)
      @bot.raw "MODE #@name -o #{user}"
    end

    # @param [String, User] user the user to voice
    # @return [void]
    def voice(user)
      @bot.raw "MODE #@name +v #{user}"
    end

    # @param [String, User] user the user to devoice
    # @return [void]
    def devoice(user)
      @bot.raw "MODE #@name -v #{user}"
    end

    # Invites a user to the channel.
    #
    # @param [String, User] user the user to invite
    # @return [void]
    def invite(user)
      @bot.raw("INVITE #{user} #@name")
    end

    # Sets the topic.
    #
    # @param [String] new_topic the new topic
    # @raise [Exceptions::TopicTooLong]
    def topic=(new_topic)
      if new_topic.size > @bot.irc.isupport["TOPICLEN"] && @bot.strict?
        raise Exceptions::TopicTooLong, new_topic
      end

      @bot.raw "TOPIC #@name :#{new_topic}"
    end

    # Kicks a user from the channel.
    #
    # @param [String, User] user the user to kick
    # @param [String] a reason for the kick
    # @raise [Exceptions::KickReasonTooLong]
    # @return [void]
    def kick(user, reason = nil)
      if reason.to_s.size > @bot.irc.isupport["KICKLEN"] && @bot.strict?
        raise Exceptions::KickReasonTooLong, reason
      end

      @bot.raw("KICK #@name #{user} :#{reason}")
    end

    # Sets or unsets modes. Most of the time you won't need this but
    # use setter methods like {Channel#invite_only=}.
    #
    # @param [String] s a mode string
    # @return [void]
    # @example
    #   channel.mode "+n"
    def mode(s)
      @bot.raw "MODE #@name #{s}"
    end

    # Causes the bot to part from the channel.
    #
    # @param [String] message the part message.
    # @return [void]
    def part(message = nil)
      @bot.raw "PART #@name :#{message}"
    end

    # Joins the channel
    #
    # @param [String] key the channel key, if any. If none is
    #   specified but @key is set, @key will be used
    # @return [void]
    def join(key = nil)
      if key.nil? and self.key != true
        key = self.key
      end
      @bot.raw "JOIN #{[@name, key].compact.join(" ")}"
    end

    # @endgroup

    # @api private
    # @return [void]
    def add_user(user, modes = [])
      @in_channel = true if user == @bot
      @users[user] = modes
    end

    # @api private
    # @return [void]
    def remove_user(user)
      @in_channel = false if user == @bot
      @users.delete(user)
    end

    # Removes all users
    #
    # @api private
    # @return [void]
    def clear_users
      @users.clear
    end

    # @return [Boolean]
    def ==(other)
      @name == other.to_s
    end
    alias_method :eql?, "=="

    # @return [Fixnum]
    def hash
      @name.hash
    end

    # @return [String]
    def to_s
      @name
    end
    alias_method :to_str, :to_s

    # @return [String]
    def inspect
      "#<Channel name=#{@name.inspect}>"
    end
  end
end
