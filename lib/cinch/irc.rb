module Cinch
  class IRC
    # @return [ISupport]
    attr_reader :isupport
    def initialize(bot)
      @bot      = bot
      @isupport = ISupport.new
    end

    # Establish a connection.
    #
    # @return [void]
    def connect
      @registration = []

      @whois_updates = Hash.new {|h, k| h[k] = {}}
      @in_lists      = Set.new

      tcp_socket = TCPSocket.open(@bot.config.server, @bot.config.port, @bot.config.local_host)

      if @bot.config.ssl
        require 'openssl'

        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

        @bot.logger.debug "Using SSL with #{@bot.config.server}:#{@bot.config.port}"

        @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
        @socket.sync = true
        @socket.connect
      else
        @socket = tcp_socket
      end

      @queue = MessageQueue.new(@socket, @bot)
      message "PASS #{@bot.config.password}" if @bot.config.password
      message "NICK #{@bot.config.nick}"
      message "USER #{@bot.config.nick} 0 * :#{@bot.config.realname}"

      Thread.new do
        begin
          while line = @socket.gets
            begin
              line.force_encoding(@bot.config.encoding).encode!({:invalid => :replace, :undef => :replace})
              parse line
            rescue => e
              @bot.logger.log_exception(e)
            end
          end
        rescue => e
          @bot.logger.log_exception(e)
        end

        @bot.dispatch(:disconnect)
      end
      begin
        @queue.process!
      rescue => e
        @bot.logger.log_exception(e)
      end
    end

    # @api private
    # @return [void]
    def parse(input)
      @bot.logger.log(input, :incoming) if @bot.config.verbose
      msg          = Message.new(input, @bot)
      events       = []

      if ("001".."004").include? msg.command
        @registration << msg.command
        if registered?
          events << :connect
        end
      elsif ["PRIVMSG", "NOTICE"].include?(msg.command)
        events << :ctcp if msg.ctcp?
        if msg.channel?
          events << :channel
        else
          events << :private
        end

        if msg.command == "PRIVMSG"
          events << :message
        else
          events << :notice
        end
      else
        meth = "on_#{msg.command.downcase}"
        __send__(meth, msg) if respond_to?(meth, true)

        if msg.error?
          events << :error
        else
          events << msg.command.downcase.to_sym
        end
      end

      msg.instance_variable_set(:@events, events)
      events.each do |event|
        @bot.dispatch(event, msg)
      end
    end

    # @return [Boolean] true if we successfully registered yet
    def registered?
      (("001".."004").to_a - @registration).empty?
    end

    # Send a message.
    # @return [void]
    def message(msg)
      @queue.queue(msg)
    end

    private
    def on_join(msg)
      if msg.user == @bot
        @bot.channels << msg.channel
        msg.channel.sync_modes
      end
      msg.channel.add_user(msg.user)
    end

    def on_kick(msg)
      target = User.find_ensured(msg.params[1], @bot)
      if target == @bot
        @bot.channels.delete(msg.channel)
      end
      msg.channel.remove_user(target)
    end

    def on_kill(msg)
      user = User.find_ensured(msg.params[1], @bot)
      Channel.all.each do |channel|
        channel.remove_user(user)
      end
      msg.user.unsync_all
      User.delete(user)
    end

    def on_mode(msg)
      msg.channel.sync_modes if msg.channel?
    end

    def on_nick(msg)
      if msg.user == @bot
        @bot.config.nick = msg.params.last
      end

      msg.user.update_nick(msg.params.last)
    end

    def on_part(msg)
      msg.channel.remove_user(msg.user)
      if msg.user == @bot
        @bot.channels.delete(msg.channel)
      end
    end

    def on_ping(msg)
      message "PONG :#{msg.params.first}"
    end

    def on_topic(msg)
      msg.channel.sync(:topic, msg.params[1])
    end

    def on_quit(msg)
      Channel.all.each do |channel|
        channel.remove_user(msg.user)
      end
      msg.user.unsync_all
      User.delete(msg.user)
    end

    def on_005(msg)
      # ISUPPORT
      @isupport.parse(*msg.params[1..-2].map {|v| v.split(" ")}.flatten)
    end

    def on_307(msg)
      # RPL_WHOISREGNICK
      user = User.find_ensured(msg.params[1], @bot)
      @whois_updates[user].merge!({:authname => user.nick})
    end

    def on_311(msg)
      # RPL_WHOISUSER
      user = User.find_ensured(msg.params[1], @bot)
      @whois_updates[user].merge!({
                                    :user => msg.params[2],
                                    :host => msg.params[3],
                                    :realname => msg.params[5],
                                  })
    end

    def on_317(msg)
      # RPL_WHOISIDLE
      user = User.find_ensured(msg.params[1], @bot)
      @whois_updates[user].merge!({
                                    :idle => msg.params[2].to_i,
                                    :signed_on_at => Time.at(msg.params[3].to_i),
                                  })
    end

    def on_318(msg)
      # RPL_ENDOFWHOIS
      user = User.find_ensured(msg.params[1], @bot)

      if @whois_updates[user].empty? && !user.attr(:unknown?, true, true)
        user.end_of_whois(nil)
      else
        user.end_of_whois(@whois_updates[user])
        @whois_updates.delete user
      end
    end

    def on_319(msg)
      # RPL_WHOISCHANNELS
      user = User.find_ensured(msg.params[1], @bot)
      channels = msg.params[2].scan(/#{@isupport["CHANTYPES"].join}[^ ]+/o).map {|c| Channel.find_ensured(c, @bot) }
      user.sync(:channels, channels, true)
    end

    def on_324(msg)
      # RPL_CHANNELMODEIS

      modes = {}
      arguments = msg.params[3..-1]
      msg.params[2][1..-1].split("").each do |mode|
        if (@isupport["CHANMODES"]["B"] + @isupport["CHANMODES"]["C"]).include?(mode)
          modes[mode] = arguments.shift
        else
          modes[mode] = true
        end
      end

      msg.channel.sync(:modes, modes, false)
    end

    def on_330(msg)
      # RPL_WHOISACCOUNT
      user = User.find_ensured(msg.params[1], @bot)
      authname = msg.params[2]
      @whois_updates[user].merge!({:authname => authname})
    end

    def on_331(msg)
      # RPL_NOTOPIC
      msg.channel.sync(:topic, "")
    end

    def on_332(msg)
      # RPL_TOPIC
      msg.channel.sync(:topic, msg.params[2])
    end

    def on_353(msg)
      # RPL_NAMEREPLY
      unless @in_lists.include?(:names)
        msg.channel.clear_users
      end
      @in_lists << :names

      msg.params[3].split(" ").each do |user|
        if @isupport["PREFIX"].values.include?(user[0..0])
          prefix = user[0..0]
          nick   = user[1..-1]
        else
          nick   = user
          prefix = nil
        end
        user = User.find_ensured(nick, @bot)
        msg.channel.add_user(user, prefix)
      end
    end

    def on_366(msg)
      # RPL_ENDOFNAMES
      @in_lists.delete :names
      msg.channel.mark_as_synced(:users)
    end

    def on_367(msg)
      # RPL_BANLIST
      unless @in_lists.include?(:bans)
        msg.channel.bans_unsynced.clear
      end
      @in_lists << :bans

      mask = msg.params[2]
      by   = User.find_ensured(msg.params[3].split("!").first, @bot)
      at   = Time.at(msg.params[4].to_i)

      ban = Ban.new(mask, by, at)
      msg.channel.bans_unsynced << ban
    end

    def on_368(msg)
      # RPL_ENDOFBANLIST
      if @in_lists.include?(:bans)
        @in_lists.delete :bans
      else
        # we never received a ban, yet an end of list => no bans
        msg.channel.bans_unsynced.clear
      end

      msg.channel.mark_as_synced(:bans)
    end

    def on_396(msg)
      # note: designed for freenode
      User.find_ensured(msg.params[0], @bot).sync(:host, msg.params[1], true)
    end

    def on_401(msg)
      # ERR_NOSUCHNICK
      user = User.find_ensured(msg.params[1], @bot)
      user.sync(:unknown?, true, true)
      if @whois_updates.key?(user)
        user.end_of_whois(nil, true)
        @whois_updates.delete user
      end
    end

    def on_402(msg)
      # ERR_NOSUCHSERVER

      if user = User.find(msg.params[1]) # not _ensured, we only want a user that already exists
        user.end_of_whois(nil, true)
        @whois_updates.delete user
        # TODO freenode specific, test on other IRCd
      end
    end

    def on_433(msg)
      # ERR_NICKNAMEINUSE
      @bot.nick = msg.params[1] + "_"
    end

    def on_671(msg)
      user = User.find_ensured(msg.params[1], @bot)
      @whois_updates[user].merge!({:secure? => true})
    end
  end
end
