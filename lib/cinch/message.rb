# -*- coding: utf-8 -*-
module Cinch
  # @attr_reader user
  # @attr_reader error
  # @attr_reader message
  # @attr_reader server
  # @attr_reader target
  # @attr_reader channel
  # @attr_reader action_message
  # @attr_reader ctcp_args
  # @attr_reader ctcp_command
  # @attr_reader ctcp_message
  class Message
    # @return [String]
    attr_accessor :raw

    # @return [String]
    attr_accessor :prefix

    # @return [String]
    attr_accessor :command

    # @return [Array<String>]
    attr_accessor :params

    # @return [Array<Symbol>]
    attr_reader :events

    # @return [Bot]
    # @since 1.1.0
    attr_reader :bot

    # @return [User, nil] If the type of message is a leaving event
    #   (KICK, KILL, PART or QUIT), then this attribute will return
    #   the user who left
    attr_reader :leaving_user
    # @api private
    attr_writer :leaving_user

    def initialize(msg, bot)
      @raw = msg
      @bot = bot
      @matches = {:ctcp => {}, :other => {}}
      @events = []
      parse if msg
    end

    # @api private
    # @return [void]
    def parse
      match = @raw.match(/(^:(\S+) )?(\S+)(.*)/)
      _, @prefix, @command, raw_params = match.captures

      if @bot.irc.network == "ngametv"
        if @prefix != "ngame"
          @prefix = "%s!user@host" % [@prefix, @prefix, @prefix]
        end
      end

      raw_params.strip!
      if match = raw_params.match(/(?:^:| :)(.*)$/)
        @params = match.pre_match.split(" ")
        @params << match[1]
      else
        @params = raw_params.split(" ")
      end
    end

    # @return [User] The user who sent this message
    def user
      return unless @prefix
      nick = @prefix[/^(\S+)!/, 1]
      user = @prefix[/^\S+!(\S+)@/, 1]
      host = @prefix[/@(\S+)$/, 1]

      return nil if nick.nil?
      @user ||= @bot.user_manager.find_ensured(user, nick, host)
    end

    # @return [String, nil]
    def server
      return unless @prefix
      return if @prefix.match(/[@!]/)
      @server ||= @prefix[/^(\S+)/, 1]
    end

    # @return [Number, nil] the numeric error code, if any
    def error
      @error ||= (command.to_i if numeric_reply? && command[/[45]\d\d/])
    end

    # @group Type checking

    # @return [Boolean] true if the message is an numeric reply (as
    #   opposed to a command)
    def numeric_reply?
      !!(@numeric_reply ||= @command.match(/^\d{3}$/))
    end

    # @return [Boolean] true if the message describes an error
    def error?
      !!error
    end

    # @return [Boolean] true if this message was sent in a channel
    def channel?
      !!channel
    end

    # @return [Boolean] true if the message is an CTCP message
    def ctcp?
      !!(params.last =~ /\001.+\001/)
    end

    # @return [Boolean] true if the message is an action (/me)
    # @since 1.2.0
    def action?
      ctcp_command == "ACTION"
    end

    # @endgroup

    # @return [String, nil] The action message
    # @since 1.2.0
    def action_message
      return nil unless action?
      ctcp_message.split(" ", 2).last
    end

    # @return [String, nil] the command part of an CTCP message
    def ctcp_command
      return unless ctcp?
      ctcp_message.split(" ").first
    end

    # @return [Channel] The channel in which this message was sent
    def channel
      @channel ||= begin
                     case command
                     when "INVITE", RPL_CHANNELMODEIS.to_s, RPL_BANLIST.to_s
                       @bot.channel_manager.find_ensured(params[1])
                     when RPL_NAMEREPLY.to_s
                       @bot.channel_manager.find_ensured(params[2])
                     else
                       if params.first.start_with?("#")
                         @bot.channel_manager.find_ensured(params.first)
                       elsif numeric_reply? and params[1].start_with?("#")
                         @bot.channel_manager.find_ensured(params[1])
                       end
                     end
                   end
    end

    # @return [Target]
    def target
      channel || user
    end

    # @api private
    # @return [MatchData]
    def match(regexp, type)
      if type == :ctcp
        @matches[:ctcp][regexp] ||= ctcp_message.match(regexp)
      else
        @matches[:other][regexp] ||= message.to_s.match(regexp)
      end
    end

    # @return [String, nil] the CTCP message, without \001 control characters
    def ctcp_message
      return unless ctcp?
      params.last =~ /\001(.+)\001/
      $1
    end

    # @return [Array<String>, nil]
    def ctcp_args
      return unless ctcp?
      ctcp_message.split(" ")[1..-1]
    end

    # @return [String, nil]
    def message
      @message ||= begin
                     if error?
                       error.to_s
                     elsif regular_command?
                       params.last
                     end
                   end
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
      if channel && prefix
        text = text.split("\n").map {|l| "#{user.nick}: #{l}"}.join("\n")
      end

      target.send(text)
    end

    # Like #reply, but using {Target#safe_send} instead
    #
    # @param (see #reply)
    # @return (see #reply)
    def safe_reply(text, prefix = false)
      text = text.to_s
      if channel && prefix
        text = "#{user.nick}: #{text}"
      end
      target.safe_send(text)
    end

    # Reply to a CTCP message
    #
    # @return [void]
    def ctcp_reply(answer)
      return unless ctcp?
      user.notice "\001#{ctcp_command} #{answer}\001"
    end

    # @endgroup

    # @return [String]
    # @since 1.1.0
    def to_s
      "#<Cinch::Message @raw=#{raw.chomp.inspect} @params=#{@params.inspect} channel=#{channel.inspect} user=#{user.inspect}>"
    end

    private
    def regular_command?
      !numeric_reply? # a command can only be numeric or "regular"…
    end
  end
end
