module Cinch
  class IRC
    # @return [ISupport]
    attr_reader :isupport
    def initialize(bot, config)
      @bot, @config = bot, config
      @isupport = ISupport.new
    end

    # Establish a connection.
    #
    # @return [void]
    def connect
      @registration = []

      @whois_updates = Hash.new {|h, k| h[k] = {}}
      @in_lists      = Set.new

      tcp_socket = TCPSocket.open(@config.server, @config.port)

      if @config.ssl
        require 'openssl'

        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

        @bot.logger.debug "Using SSL with #{@config.server}:#{@config.port}"

        @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
        @socket.sync = true
        @socket.connect
      else
        @socket = tcp_socket
      end
      @socket.set_encoding(@bot.config.encoding || Encoding.default_external,
                           Encoding.default_internal,
                           {:invalid => :replace, :undef => :replace})

      @queue = MessageQueue.new(@socket, @bot)
      message "PASS #{@config.password}" if @config.password
      message "NICK #{@config.nick}"
      message "USER #{@config.nick} 0 * :#{@config.realname}"

      Thread.new do
        begin
          while line = @socket.gets
            begin
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
      dispatch_msg = nil

      if msg.command == ERR_NICKNAMEINUSE.to_s
        @bot.nick = msg.params[1] + "_"
      end

      if ("001".."004").include? msg.command
        @registration << msg.command
        if registered?
          events << :connect
        end
      elsif msg.command == "PRIVMSG"
        events.concat(if msg.ctcp?
                        [:ctcp]
                      elsif msg.channel?
                        [:message, :channel]
                      else
                        [:message, :private]
                      end)

        dispatch_msg = msg
      elsif msg.command == "NOTICE"
        events.concat(if msg.ctcp?
                        [:ctcp]
                      elsif msg.channel?
                        [:notice, :channel]
                      else
                        [:notice, :private]
                      end)

        dispatch_msg = msg
      elsif msg.command == "PING"
        events << :ping
        message "PONG :#{msg.params.first}"
      else
        if msg.command == "005"
          @isupport.parse(*msg.params[1..-2].map {|v| v.split(" ")}.flatten)
        elsif [RPL_TOPIC.to_s, RPL_NOTOPIC.to_s, "TOPIC"].include?(msg.command)
          topic = case msg.command
                  when RPL_TOPIC.to_s
                    msg.params[2]
                  when "TOPIC"
                    msg.params[1]
                  else
                    ""
                  end
          msg.channel.sync(:topic, topic)
        elsif msg.command == "JOIN"
          if msg.user == @bot
            msg.channel.sync_modes
          end
          msg.channel.add_user(msg.user)
        elsif msg.command == "PART"
          msg.channel.remove_user(msg.user)
        elsif msg.command == "KICK"
          msg.channel.remove_user(User.find_ensured(msg.params[1], @bot))
        elsif msg.command == "KILL"
          user = User.find_ensured(msg.params[1], @bot)
          Channel.all.each do |channel|
            channel.remove_user(user)
          end
        elsif msg.command == "QUIT"
          Channel.all.each do |channel|
            channel.remove_user(msg.user)
          end
          msg.user.synced = false
        elsif msg.command == "NICK"
          if msg.user == @bot
            @bot.config.nick = msg.params.last
          end

          msg.user.nick = msg.params.last
        elsif msg.command == "MODE"
          msg.channel.sync_modes if msg.channel?
        elsif msg.command == RPL_CHANNELMODEIS.to_s
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
        elsif msg.command == RPL_NAMEREPLY.to_s
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

        elsif msg.command == RPL_WHOISUSER.to_s
          user = User.find_ensured(msg.params[1], @bot)
          @whois_updates[user].merge!({
                                        :user => msg.params[2],
                                        :host => msg.params[3],
                                        :realname => msg.params[5],
                                      })
        elsif msg.command == RPL_WHOISACCOUNT.to_s
          user = User.find_ensured(msg.params[1], @bot)
          authname = msg.params[2]
          @whois_updates[user].merge!({:authname => authname})
        elsif msg.command == RPL_WHOISCHANNELS.to_s
          user = User.find_ensured(msg.params[1], @bot)
          channels = msg.params[2].scan(/#{@isupport["CHANTYPES"].join}[^ ]+/o).map {|c| Channel.find_ensured(c, @bot) }
          user.sync(:channels, channels, true)
        elsif msg.command == RPL_WHOISIDLE.to_s
          user = User.find_ensured(msg.params[1], @bot)
          @whois_updates[user].merge!({
                                        :idle => msg.params[2].to_i,
                                        :signed_on_at => Time.at(msg.params[3].to_i),
                                      })
        elsif msg.command == "671"
          user = User.find_ensured(msg.params[1], @bot)
          @whois_updates[user].merge!({:secure? => true})
        elsif msg.command == ERR_NOSUCHSERVER.to_s
          if user = User.find(msg.params[1]) # not _ensured, we only want a user that already exists
            user.sync(:unknown?, true, true)
            @whois_updates.delete user
            # TODO freenode specific, test on other IRCd
          end
        elsif msg.command == ERR_NOSUCHNICK.to_s
          user = User.find_ensured(msg.params[1], @bot)
          user.sync(:unknown?, true, true)
        elsif msg.command == RPL_ENDOFWHOIS.to_s
          user = User.find_ensured(msg.params[1], @bot)
          user.in_whois = false
          if @whois_updates[user].empty? && !user.attr(:unknown?, true, true)
            # for some reason, we did not receive user information. one
            # reason is freenode throttling WHOIS
            Thread.new do
              sleep 2
              user.whois
            end
          else
            {
              :authname => nil,
              :idle => 0,
              :secure? => false,
            }.merge(@whois_updates[user]).each do |attr, value|
              user.sync(attr, value, true)
            end

            user.sync(:unknown?, false, true)
            user.synced = true
            @whois_updates.delete user
          end
        elsif msg.command == RPL_ENDOFNAMES.to_s
          @in_lists.delete :names
          msg.channel.mark_as_synced(:users)
        elsif msg.command == RPL_BANLIST.to_s
          unless @in_lists.include?(:bans)
            msg.channel.bans_unsynced.clear
          end
          @in_lists << :bans

          mask = msg.params[2]
          by   = User.find_ensured(msg.params[3].split("!").first, @bot)
          at   = Time.at(msg.params[4].to_i)

          ban = Ban.new(mask, by, at)
          msg.channel.bans_unsynced << ban
        elsif msg.command == RPL_ENDOFBANLIST.to_s
          if @in_lists.include?(:bans)
            @in_lists.delete :bans
          else
            # we never received a ban, yet an end of list => no bans
            msg.channel.bans_unsynced.clear
          end

          msg.channel.mark_as_synced(:bans)
        elsif msg.command == "396"
          # note: designed for freenode
          User.find_ensured(msg.params[0], @bot).sync(:host, msg.params[1], true)
        end

        # TODO work with strings/constants, too

        if msg.error?
          events << :error
        else
          events << msg.command.downcase.to_sym
        end

        dispatch_msg = msg
      end

      msg.instance_variable_set(:@events, events)

      events.each do |event|
        @bot.dispatch(event, dispatch_msg)
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
  end
end
