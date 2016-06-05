# -*- coding: utf-8 -*-
require "time"
require "cinch/formatting"

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
    
    # @return [Hash]
    attr_reader :tags

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

    # The STATUSMSG mode a channel message was sent to.
    #
    # Some IRC servers allow sending messages limited to people in a
    # channel who have a certain mode. For example, by sending a
    # message to `+#channel`, only people who are voiced, or have a
    # higher mode (op) will receive the message.
    #
    # This attribute contains the mode character the message was sent
    # to, or nil if it was a normal message. For the previous example,
    # this attribute would be set to `"v"`, for voiced.
    #
    # @return [String, nil]
    # @since 2.3.0
    attr_reader :statusmsg_mode

    def initialize(msg, bot)
      @raw     = msg
      @bot     = bot
      @matches = {:ctcp => {}, :action => {}, :other => {}}
      @events  = []
      @time    = Time.now
      @statusmsg_mode = nil
      parse if msg
    end

    # @api private
    # @return [void]
    def parse
      match = @raw.match(/(?:^@([^:]+))?(?::?(\S+) )?(\S+)(.*)/)
      tags, @prefix, @command, raw_params = match.captures

      if @bot.irc.network.ngametv?
        if @prefix != "ngame"
          @prefix = "%s!%s@%s" % [@prefix, @prefix, @prefix]
        end
      end

      @params  = parse_params(raw_params)
      @tags    = parse_tags(tags)

      @user    = parse_user
      @channel, @statusmsg_mode = parse_channel
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
        text = Cinch::Formatting.unformat(text)
      end

      @matches[type][regexp] ||= text.match(regexp)
    end

    # @group Replying

    # Replies to a message, automatically determining if it was a
    # channel or a private message.
    #
    # If the message is a STATUSMSG, i.e. it was send to `+#channel`
    # or `@#channel` instead of `#channel`, the reply will be sent as
    # the same kind of STATUSMSG. See {#statusmsg_mode} for more
    # information on STATUSMSG.
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

      reply_target.send(text)
    end

    # Like {#reply}, but using {Target#safe_send} instead
    #
    # @param (see #reply)
    # @return (see #reply)
    def safe_reply(text, prefix = false)
      text = text.to_s
      if channel && prefix
        text = "#{@user.nick}: #{text}"
      end
      reply_target.safe_send(text)
    end

    # Reply to a message with an action.
    #
    # For its behaviour with regard to STATUSMSG, see {#reply}.
    #
    # @param [String] text the action message
    # @return [void]
    def action_reply(text)
      text = text.to_s
      reply_target.action(text)
    end

    # Like {#action_reply}, but using {Target#safe_action} instead
    #
    # @param (see #action_reply)
    # @return (see #action_reply)
    def safe_action_reply(text)
      text = text.to_s
      reply_target.safe_action(text)
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
    def reply_target
      if @channel.nil? || @statusmsg_mode.nil?
        return @target
      end
      prefix = @bot.irc.isupport["PREFIX"][@statusmsg_mode]
      return Target.new(prefix + @channel.name, @bot)
    end
    def regular_command?
      !numeric_reply? # a command can only be numeric or "regular"…
    end

    def parse_params(raw_params)
      params     = []
      if match = raw_params.match(/(?:^:| :)(.*)$/)
        params = match.pre_match.split(" ")
        params << match[1]
      else
        params = raw_params.split(" ")
      end

      return params
    end
    
    def parse_tags(raw_tags)
      return {} if raw_tags.nil?
      
      def to_symbol(string)
        return string.gsub(/-/, "_").downcase.to_sym
      end
      
      tags = {}
      raw_tags.split(";").each do |tag|
        key, value = tag.split("=")
        if value =~ /,/
          _value = value
          value = {}
          _value.split(",").each do |item|
            _key, _value = item.split "/"
            value[to_symbol(_key)] = _value
          end
        end
        tags[to_symbol(key)] = value
      end
      return tags
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
      return nil if @params.empty?

      case @command
      when "INVITE", Constants::RPL_CHANNELMODEIS.to_s, Constants::RPL_BANLIST.to_s
        @bot.channel_list.find_ensured(@params[1])
      when Constants::RPL_NAMEREPLY.to_s
        @bot.channel_list.find_ensured(@params[2])
      else
        # Note that this will also find channels for messages that
        # don't actually include a channel parameter. For example
        # `QUIT :#sometext` will be interpreted as a channel. The
        # alternative to the currently used heuristic would be to
        # hardcode a list of commands that provide a channel argument.
        ch, status = privmsg_channel_name(@params.first)
        if ch.nil? && numeric_reply? && @params.size > 1
          ch, status = privmsg_channel_name(@params[1])
        end
        if ch
          return @bot.channel_list.find_ensured(ch), status
        end
      end
    end

    def privmsg_channel_name(s)
      chantypes = @bot.irc.isupport["CHANTYPES"]
      statusmsg = @bot.irc.isupport["STATUSMSG"]
      if statusmsg.include?(s[0]) && chantypes.include?(s[1])
        status = @bot.irc.isupport["PREFIX"].invert[s[0]]
        return s[1..-1], status
      elsif chantypes.include?(s[0])
        return s, nil
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
