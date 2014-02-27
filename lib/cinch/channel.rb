# -*- coding: utf-8 -*-
require "set"
require "cinch/target"

module Cinch
  # @attr limit
  # @attr secret
  # @attr moderated
  # @attr invite_only
  # @attr key
  #
  # @version 2.0.0
  class Channel < Target
    include Syncable
    include Helpers

    # Users are represented by a Hash, mapping individual users to an
    # array of modes (e.g. "o" for opped).
    #
    # @return [Hash{User => Array<String}>] all users in the channel
    # @version 1.1.0
    attr_reader :users
    synced_attr_reader :users

    # @return [String] the channel's topic
    attr_accessor :topic
    synced_attr_reader :topic

    # @return [Array<Ban>] all active bans
    attr_reader :bans
    synced_attr_reader :bans

    # @return [Array<User>] all channel owners
    # @note Only some networks implement this
    attr_reader :owners
    synced_attr_reader :owners

    # This attribute describes all modes set in the channel. They're
    # represented as a Hash, mapping the mode (e.g. "i", "k", …) to
    # either a value in the case of modes that take an option (e.g.
    # "k" for the channel key) or true.
    #
    # @return [Hash{String => Object}]
    attr_reader :modes
    synced_attr_reader :modes
    def initialize(name, bot)
      @bot    = bot
      @name   = name
      @users  = Hash.new {|h, k| h[k] = []}
      @bans   = []
      @owners = []

      @modes = {}
      # TODO raise if not a channel

      @topic = nil

      @in_channel = false

      @synced_attributes  = Set.new
      @when_requesting_synced_attribute = lambda {|attr|
        if @in_channel && attr == :topic && !attribute_synced?(:topic)
          # Even if we are in the channel, if there's no topic set,
          # the attribute won't be synchronised yet. Explicitly
          # request the topic.
          @bot.irc.send "TOPIC #@name"
          next
        end

        unless @in_channel
          unsync(attr)
          case attr
          when :users
            @bot.irc.send "NAMES #@name"
          when :topic
            @bot.irc.send "TOPIC #@name"
          when :bans
            @bot.irc.send "MODE #@name +b"
          when :owners
            if @bot.irc.network.owner_list_mode
              @bot.irc.send "MODE #@name +#{@bot.irc.network.owner_list_mode}"
            else
              # the current IRCd does not support channel owners, so
              # just mark the empty array as synced
              mark_as_synced(:owners)
            end
          when :modes
            @bot.irc.send "MODE #@name"
          end
        end
      }
    end

    # @group Checks

    # @param [User, String] user An {User}-object or a nickname
    # @return [Boolean] Check if a user is in the channel
    # @since 1.1.0
    # @version 1.1.2
    def has_user?(user)
      @users.has_key?(User(user))
    end

    # @return [Boolean] true if `user` is opped in the channel
    # @since 1.1.0
    def opped?(user)
      @users[User(user)].include? "o"
    end

    # @return [Boolean] true if `user` is half-opped in the channel
    # @since 1.1.0
    def half_opped?(user)
      @users[User(user)].include? "h"
    end

    # @return [Boolean] true if `user` is voiced in the channel
    # @since 1.1.0
    def voiced?(user)
      @users[User(user)].include? "v"
    end

    # @endgroup

    # @group User groups
    # @return [Array<User>] All ops in the channel
    # @since 2.0.0
    def ops
      @users.select {|user, modes| modes.include?("o")}.keys
    end

    # @return [Array<User>] All half-ops in the channel
    # @since 2.0.0
    def half_ops
      @users.select {|user, modes| modes.include?("h")}.keys
    end

    # @return [Array<User>] All voiced users in the channel
    # @since 2.0.0
    def voiced
      @users.select {|user, modes| modes.include?("v")}.keys
    end

    # @return [Array<User>] All admins in the channel
    # @since 2.0.0
    def admins
      @users.select {|user, modes| modes.include?("a")}.keys
    end
    # @endgroup

    # @return [Integer] The maximum number of allowed users in the
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

    # @return [Boolean] true if the channel is moderated
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
    def sync_modes
      unsync :users
      unsync :bans
      unsync :modes
      unsync :owners

      if @bot.irc.isupport["WHOX"]
        @bot.irc.send "WHO #@name %acfhnru"
      else
        @bot.irc.send "WHO #@name"
      end
      @bot.irc.send "MODE #@name +b" # bans
      @bot.irc.send "MODE #@name"
      if @bot.irc.network.owner_list_mode
        @bot.irc.send "MODE #@name +#{@bot.irc.network.owner_list_mode}"
      else
        mark_as_synced :owners
      end
    end

    # @group Channel Manipulation

    # Bans someone from the channel.
    #
    # @param [Mask, String, #mask] target the mask, or an object having a mask, to ban
    # @return [Mask] the mask used for banning
    # @see #unban #unban for unbanning users
    def ban(target)
      mask = Mask.from(target)

      @bot.irc.send "MODE #@name +b #{mask}"
      mask
    end

    # Unbans someone from the channel.
    #
    # @param [Mask, String, #mask] target the mask to unban
    # @return [Mask] the mask used for unbanning
    # @see #ban #ban for banning users
    def unban(target)
      mask = Mask.from(target)

      @bot.irc.send "MODE #@name -b #{mask}"
      mask
    end

    # Ops a user.
    #
    # @param [String, User] user the user to op
    # @return [void]
    def op(user)
      @bot.irc.send "MODE #@name +o #{user}"
    end

    # Deops a user.
    #
    # @param [String, User] user the user to deop
    # @return [void]
    def deop(user)
      @bot.irc.send "MODE #@name -o #{user}"
    end

    # Voices a user.
    #
    # @param [String, User] user the user to voice
    # @return [void]
    def voice(user)
      @bot.irc.send "MODE #@name +v #{user}"
    end

    # Devoices a user.
    #
    # @param [String, User] user the user to devoice
    # @return [void]
    def devoice(user)
      @bot.irc.send "MODE #@name -v #{user}"
    end

    # Invites a user to the channel.
    #
    # @param [String, User] user the user to invite
    # @return [void]
    def invite(user)
      @bot.irc.send("INVITE #{user} #@name")
    end

    undef_method(:topic=)
    # Sets the topic.
    #
    # @param [String] new_topic the new topic
    # @raise [Exceptions::TopicTooLong] Raised if the bot is operating
    #   in {Bot#strict? strict mode} and when the new topic is too long.
    def topic=(new_topic)
      if new_topic.size > @bot.irc.isupport["TOPICLEN"] && @bot.strict?
        raise Exceptions::TopicTooLong, new_topic
      end

      @bot.irc.send "TOPIC #@name :#{new_topic}"
    end

    # Kicks a user from the channel.
    #
    # @param [String, User] user the user to kick
    # @param [String] reason a reason for the kick
    # @raise [Exceptions::KickReasonTooLong]
    # @return [void]
    def kick(user, reason = nil)
      if reason.to_s.size > @bot.irc.isupport["KICKLEN"] && @bot.strict?
        raise Exceptions::KickReasonTooLong, reason
      end

      @bot.irc.send("KICK #@name #{user} :#{reason}")
    end

    # Sets or unsets modes. Most of the time you won't need this but
    # use setter methods like {Channel#invite_only=}.
    #
    # @param [String] s a mode string
    # @return [void]
    # @example
    #   channel.mode "+n"
    def mode(s)
      @bot.irc.send "MODE #@name #{s}"
    end

    # Causes the bot to part from the channel.
    #
    # @param [String] message the part message.
    # @return [void]
    def part(message = nil)
      @bot.irc.send "PART #@name :#{message}"
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
      @bot.irc.send "JOIN #{[@name, key].compact.join(" ")}"
    end

    # @endgroup

    # @api private
    # @return [User] The added user
    def add_user(user, modes = [])
      @in_channel = true if user == @bot
      @users[user] = modes
      user
    end

    # @api private
    # @return [User, nil] The removed user
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

    def msg(text, notice = false)
      text = text.to_s
      if @modes["c"]
        # Remove all formatting and colors if the channel doesn't
        # allow colors.
        text.gsub!(/[\x02\x1F\x16\x0F]|\x03\d{2}(,\d{2})?/, "")
      end
      super(text, notice)
    end
    alias_method :send, :msg
    alias_method :privmsg, :msg

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
