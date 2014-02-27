# -*- coding: utf-8 -*-
require "time"
require "cinch/utilities/string"

module Cinch
  # This class serves two purposes. For one, it simply
  # represents incoming messages and allows for querying various
  # details (who sent the message, what kind of message it is, etc).
  #
  # At the same time, it allows **responding** to messages, which
  # means sending messages to either users or channels.
  class Message
    # @return [String]
    attr_reader :raw

    # @return [String]
    attr_reader :prefix

    # @return [String]
    attr_reader :command

    # @return [Array<String>]
    attr_reader :params

    # @return [Array<Symbol>]
    attr_reader :events
    # @api private
    attr_writer :events

    # @return [Time]
    # @since 2.0.0
    attr_reader :time

    # @return [Bot]
    # @since 1.1.0
    attr_reader :bot

    # @return [User] The user who sent this message
    attr_reader :user

    # @return [String, nil]
    attr_reader :server

    # @return [Integer, nil] the numeric error code, if any
    attr_reader :error

    # @return [String, nil] the command part of an CTCP message
    attr_reader :ctcp_command

    # @return [Channel] The channel in which this message was sent
    attr_reader :channel

    # @return [String, nil] the CTCP message, without \001 control characters
    attr_reader :ctcp_message

    # @return [Array<String>, nil]
    attr_reader :ctcp_args

    # @return [String, nil]
    attr_reader :message

    # @return [String, nil] The action message
    # @since 2.0.0
    attr_reader :action_message

    # @return [Target]
    attr_reader :target

    def initialize(msg, bot)
      @raw     = msg
      @bot     = bot
      @matches = {:ctcp => {}, :action => {}, :other => {}}
      @events  = []
      @time    = Time.now
      parse if msg
    end

    # @api private
    # @return [void]
    def parse
      match = @raw.match(/(^:(\S+) )?(\S+)(.*)/)
      _, @prefix, @command, raw_params = match.captures

      if @bot.irc.network.ngametv?
        if @prefix != "ngame"
          @prefix = "%s!%s@%s" % [@prefix, @prefix, @prefix]
        end
      end

      @params  = parse_params(raw_params)

      @user    = parse_user
      @channel = parse_channel
      @target  = @channel || @user
      @server  = parse_server
      @error   = parse_error
      @message = parse_message

      @ctcp_message = parse_ctcp_message
      @ctcp_command = parse_ctcp_command
      @ctcp_args    = parse_ctcp_args

      @action_message = parse_action_message
    end

    # @group Type checking

    # @return [Boolean] true if the message is an numeric reply (as
    #   opposed to a command)
    def numeric_reply?
      !!@command.match(/^\d{3}$/)
    end

    # @return [Boolean] true if the message describes an error
    def error?
      !@error.nil?
    end

    # @return [Boolean] true if this message was sent in a channel
    def channel?
      !@channel.nil?
    end

    # @return [Boolean] true if the message is an CTCP message
    def ctcp?
      !!(@params.last =~ /\001.+\001/)
    end

    # @return [Boolean] true if the message is an action (/me)
    # @since 2.0.0
    def action?
      @ctcp_command == "ACTION"
    end

    # @endgroup

    # @api private
    # @return [MatchData]
    def match(regexp, type, strip_colors)
      text = ""
      case type
      when :ctcp
        text = ctcp_message
      when :action
        text = action_message
      else
        text = message.to_s
        type = :other
      end

      if strip_colors
        text = Cinch::Utilities::String.strip_colors(text)
      end

      @matches[type][regexp] ||= text.match(regexp)
    end

    # @group Replying

    # Replies to a message, automatically determining if it was a
    # channel or a private message.
    #
    # @param [String] text the message
    # @param [Boolean] prefix if prefix is true and the message was in
    #   a channel, the reply will be prefixed by the nickname of whoever
    #   send the mesage
    # @return [void]
    def reply(text, prefix = false)
      text = text.to_s
      if @channel && prefix
        text = text.split("\n").map {|l| "#{user.nick}: #{l}"}.join("\n")
      end

      @target.send(text)
    end

    # Like #reply, but using {Target#safe_send} instead
    #
    # @param (see #reply)
    # @return (see #reply)
    def safe_reply(text, prefix = false)
      text = text.to_s
      if channel && prefix
        text = "#{@user.nick}: #{text}"
      end
      @target.safe_send(text)
    end

    # Reply to a message with an action.
    #
    # @param [String] text the action message
    # @return [void]
    def action_reply(text)
      text = text.to_s
      @target.action(text)
    end

    # Like #action_reply, but using {Target#safe_action} instead
    #
    # @param (see #action_reply)
    # @return (see #action_reply)
    def safe_action_reply(text)
      text = text.to_s
      @target.safe_action(text)
    end

    # Reply to a CTCP message
    #
    # @return [void]
    def ctcp_reply(answer)
      return unless ctcp?
      @user.notice "\001#{@ctcp_command} #{answer}\001"
    end

    # @endgroup

    # @return [String]
    # @since 1.1.0
    def to_s
      "#<Cinch::Message @raw=#{@raw.chomp.inspect} @params=#{@params.inspect} channel=#{@channel.inspect} user=#{@user.inspect}>"
    end

    private
    def regular_command?
      !numeric_reply? # a command can only be numeric or "regular"…
    end

    def parse_params(raw_params)
      raw_params = raw_params.strip
      params     = []
      if match = raw_params.match(/(?:^:| :)(.*)$/)
        params = match.pre_match.split(" ")
        params << match[1]
      else
        params = raw_params.split(" ")
      end

      return params
    end

    def parse_user
      return unless @prefix
      nick = @prefix[/^(\S+)!/, 1]
      user = @prefix[/^\S+!(\S+)@/, 1]
      host = @prefix[/@(\S+)$/, 1]

      return nil if nick.nil?
      return @bot.user_list.find_ensured(user, nick, host)
    end

    def parse_channel
      # has to be called after parse_params
      case @command
      when "INVITE", Constants::RPL_CHANNELMODEIS.to_s, Constants::RPL_BANLIST.to_s
        @bot.channel_list.find_ensured(@params[1])
      when Constants::RPL_NAMEREPLY.to_s
        @bot.channel_list.find_ensured(@params[2])
      else
        chantypes = @bot.irc.isupport["CHANTYPES"]
        if chantypes.include?(@params.first[0])
          @bot.channel_list.find_ensured(@params.first)
        elsif numeric_reply? and @params.size > 1 and chantypes.include?(@params[1][0])
          @bot.channel_list.find_ensured(@params[1])
        end
      end
    end

    def parse_server
      return unless @prefix
      return if @prefix.match(/[@!]/)
      return @prefix[/^(\S+)/, 1]
    end

    def parse_error
      return @command.to_i if numeric_reply? && @command[/[45]\d\d/]
    end

    def parse_message
      # has to be called after parse_params
      if error?
        @error.to_s
      elsif regular_command?
        @params.last
      end
    end

    def parse_ctcp_message
      # has to be called after parse_params
      return unless ctcp?
      @params.last =~ /\001(.+)\001/
      $1
    end

    def parse_ctcp_command
      # has to be called after parse_ctcp_message
      return unless ctcp?
      @ctcp_message.split(" ").first
    end

    def parse_ctcp_args
      # has to be called after parse_ctcp_message
      return unless ctcp?
      @ctcp_message.split(" ")[1..-1]
    end

    def parse_action_message
      # has to be called after parse_ctcp_message
      return nil unless action?
      @ctcp_message.split(" ", 2).last
    end

  end
end
