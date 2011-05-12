require "timeout"
require "net/protocol"

module Cinch
  class IRC
    include Helpers

    # @return [ISupport]
    attr_reader :isupport
    # @return [Bot]
    attr_reader :bot
    attr_reader :network
    def initialize(bot)
      @bot      = bot
      @isupport = ISupport.new
    end

    def setup
      @registration = []
      @network = :other
      @whois_updates = Hash.new {|h, k| h[k] = {}}
      @in_lists      = Set.new
    end

    def connect
      tcp_socket = nil
      begin
        Timeout::timeout(@bot.config.timeouts.connect) do
          tcp_socket = TCPSocket.new(@bot.config.server, @bot.config.port, @bot.config.local_host)
        end
      rescue Timeout::Error
        @bot.logger.debug("Timed out while connecting")
        return
      rescue => e
        @bot.logger.log_exception(e)
        return
      end
      if @bot.config.ssl == true || @bot.config.ssl == false
        @bot.logger.debug "Deprecation warning: Beginning from version 1.1.0, @config.ssl should be a set of options, not a boolean value!"
      end

      if @bot.config.ssl == true || (@bot.config.ssl.is_a?(SSLConfiguration) && @bot.config.ssl.use)
        require 'openssl'

        ssl_context = OpenSSL::SSL::SSLContext.new

        if @bot.config.ssl.is_a?(SSLConfiguration)
          if @bot.config.ssl.client_cert
            ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(@bot.config.ssl.client_cert))
            ssl_context.key = OpenSSL::PKey::RSA.new(File.read(@bot.config.ssl.client_cert))
          end
          ssl_context.ca_path = @bot.config.ssl.ca_path
          ssl_context.verify_mode = @bot.config.ssl.verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        else
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        @bot.logger.debug "Using SSL with #{@bot.config.server}:#{@bot.config.port}"

        @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
        @socket.sync = true
        @socket.connect
      else
        @socket = tcp_socket
      end

      @socket = Net::BufferedIO.new(@socket)
      @socket.read_timeout = @bot.config.timeouts.read
      @queue = MessageQueue.new(@socket, @bot)
    end

    def send_login
      message "PASS #{@bot.config.password}" if @bot.config.password
      message "NICK #{@bot.generate_next_nick}"
      message "USER #{@bot.config.user} 0 * :#{@bot.config.realname}"
    end

    def start_reading_thread
      Thread.new do
        begin
          while line = @socket.readline
            begin
              line = Cinch.encode_incoming(line, @bot.config.encoding)
              parse line
            rescue => e
              @bot.logger.log_exception(e)
            end
          end
        rescue Timeout::Error
          @bot.logger.debug "Connection timed out."
        rescue EOFError
          @bot.logger.debug "Lost connection."
        rescue => e
          @bot.logger.log_exception(e)
        end

        @socket.close
        @bot.dispatch(:disconnect)
        @bot.handler_threads.each { |t| t.join(10); t.kill }
      end
    end

    def start_sending_thread
      Thread.new do
        begin
          @queue.process!
        rescue => e
          @bot.logger.log_exception(e)
        end
      end
    end

    def start_ping_thread
      Thread.new do
        while true
          sleep @bot.config.ping_interval
          message("PING 0") # PING requires a single argument. In our
                            # case the value doesn't matter though.
        end
      end
    end

    # Establish a connection.
    #
    # @return [void]
    def start
      setup
      connect
      send_login
      reading_thread = start_reading_thread
      sending_thread = start_sending_thread
      ping_thread    = start_ping_thread

      reading_thread.join
      sending_thread.kill
      ping_thread.kill
    end

    # @api private
    # @return [void]
    def parse(input)
      @bot.logger.log(input, :incoming) if @bot.config.verbose
      msg          = Message.new(input, @bot)
      events       = [[:catchall]]

      if ("001".."004").include? msg.command
        @registration << msg.command
        if registered?
          events << [:connect]
          @bot.last_connection_was_successful = true
        end
      end

      if ["PRIVMSG", "NOTICE"].include?(msg.command)
        events << [:ctcp] if msg.ctcp?
        if msg.channel?
          events << [:channel]
        else
          events << [:private]
        end

        if msg.command == "PRIVMSG"
          events << [:message] << [:privmsg]
        else
          events << [:notice]
        end
      else
        meth = "on_#{msg.command.downcase}"
        __send__(meth, msg, events) if respond_to?(meth, true)

        if msg.error?
          events << [:error]
        else
          events << [msg.command.downcase.to_sym]
        end
      end

      msg.instance_variable_set(:@events, events.map(&:first))
      events.each do |event, *args|
        @bot.dispatch(event, msg, *args)
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
    def on_join(msg, events)
      if msg.user == @bot
        @bot.channels << msg.channel
        msg.channel.sync_modes
      end
      msg.channel.add_user(msg.user)
    end

    def on_kick(msg, events)
      target = User(msg.params[1])
      if target == @bot
        @bot.channels.delete(msg.channel)
      end
      msg.channel.remove_user(target)
    end

    def on_kill(msg, events)
      user = User(msg.params[1])
      @bot.channel_manager.each do |channel|
        channel.remove_user(user)
      end
      user.unsync_all
      @bot.user_manager.delete(user)
    end

    def on_mode(msg, events)
      if msg.channel?
        add_and_remove = @bot.irc.isupport["CHANMODES"]["A"] + @bot.irc.isupport["CHANMODES"]["B"] + @bot.irc.isupport["PREFIX"].keys

        param_modes = {:add => @bot.irc.isupport["CHANMODES"]["C"] + add_and_remove,
          :remove => add_and_remove}

        modes = ModeParser.parse_modes(msg.params[1], msg.params[2..-1], param_modes)
        modes.each do |direction, mode, param|
          if @bot.irc.isupport["PREFIX"].keys.include?(mode)
            target = User(param)
            # (un)set a user-mode
            if direction == :add
              msg.channel.users[target] << mode unless msg.channel.users[User(param)].include?(mode)
            else
              msg.channel.users[target].delete mode
            end

            user_events = {
              "o" => "op",
              "v" => "voice",
              "h" => "halfop"
            }
            if user_events.has_key?(mode)
              event = (direction == :add ? "" : "de") + user_events[mode]
              events << [event.to_sym, target]
            end
          elsif @bot.irc.isupport["CHANMODES"]["A"].include?(mode)
            case mode
            when "b"
              mask = param
              ban = Ban.new(mask, msg.user, Time.now)

              if direction == :add
                msg.channel.bans_unsynced << ban
                events << [:ban, ban]
              else
                msg.channel.bans_unsynced.delete_if {|b| b.mask == ban.mask}.first
                events << [:unban, ban]
              end
            else
              raise UnsupportedFeature, mode
            end
          else
            # channel options
            if direction == :add
              msg.channel.modes_unsynced[mode] = param
            else
              msg.channel.modes_unsynced.delete(mode)
            end
          end
        end

        events << [:mode_change, modes]
      end
    end

    def on_nick(msg, events)
      if msg.user == @bot
        @bot.config.nick = msg.params.last
      end

      msg.user.update_nick(msg.params.last)
    end

    def on_part(msg, events)
      msg.channel.remove_user(msg.user)
      if msg.user == @bot
        @bot.channels.delete(msg.channel)
      end
    end

    def on_ping(msg, events)
      message "PONG :#{msg.params.first}"
    end

    def on_topic(msg, events)
      msg.channel.sync(:topic, msg.params[1])
    end

    def on_quit(msg, events)
      @bot.channel_manager.each do |channel|
        channel.remove_user(msg.user)
      end
      msg.user.unsync_all
      @bot.user_manager.delete(msg.user)
    end

    def on_002(msg, events)
      if msg.params.last == "Your host is jtvchat"
        # the justin tv "IRC" server lacks support for WHOIS with more
        # than one argument and does not use full banmasks in
        # RPL_BANLIST
        @network = "jtv"
      else
        # this catches all other networks that do not require custom
        # behaviour.
        @network = :other
      end
    end

    def on_005(msg, events)
      # ISUPPORT
      @isupport.parse(*msg.params[1..-2].map {|v| v.split(" ")}.flatten)
    end

    def on_307(msg, events)
      # RPL_WHOISREGNICK
      user = User(msg.params[1])
      @whois_updates[user].merge!({:authname => user.nick})
    end

    def on_311(msg, events)
      # RPL_WHOISUSER
      user = User(msg.params[1])
      @whois_updates[user].merge!({
                                    :user => msg.params[2],
                                    :host => msg.params[3],
                                    :realname => msg.params[5],
                                  })
    end

    def on_317(msg, events)
      # RPL_WHOISIDLE
      user = User(msg.params[1])
      @whois_updates[user].merge!({
                                    :idle => msg.params[2].to_i,
                                    :signed_on_at => Time.at(msg.params[3].to_i),
                                  })
    end

    def on_318(msg, events)
      # RPL_ENDOFWHOIS
      user = User(msg.params[1])

      if @whois_updates[user].empty? && !user.attr(:unknown?, true, true)
        user.end_of_whois(nil)
      else
        user.end_of_whois(@whois_updates[user])
        @whois_updates.delete user
      end
    end

    def on_319(msg, events)
      # RPL_WHOISCHANNELS
      user = User(msg.params[1])
      channels = msg.params[2].scan(/#{@isupport["CHANTYPES"].join}[^ ]+/o).map {|c| Channel(c) }
      user.sync(:channels, channels, true)
    end

    def on_324(msg, events)
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

    def on_330(msg, events)
      # RPL_WHOISACCOUNT
      user = User(msg.params[1])
      authname = msg.params[2]
      @whois_updates[user].merge!({:authname => authname})
    end

    def on_331(msg, events)
      # RPL_NOTOPIC
      msg.channel.sync(:topic, "")
    end

    def on_332(msg, events)
      # RPL_TOPIC
      msg.channel.sync(:topic, msg.params[2])
    end

    def on_353(msg, events)
      # RPL_NAMEREPLY
      unless @in_lists.include?(:names)
        msg.channel.clear_users
      end
      @in_lists << :names

      msg.params[3].split(" ").each do |user|
        m = user.match(/^([#{@isupport["PREFIX"].values.join}]+)/)
        if m
          prefixes = m[1].split.map {|s| @isupport["PREFIX"].key(s)}
          nick   = user[prefixes.size..-1]
        else
          nick   = user
          prefixes = []
        end
        user = User(nick)
        msg.channel.add_user(user, prefixes)
      end
    end

    def on_366(msg, events)
      # RPL_ENDOFNAMES
      @in_lists.delete :names
      msg.channel.mark_as_synced(:users)
    end

    def on_367(msg, events)
      # RPL_BANLIST
      unless @in_lists.include?(:bans)
        msg.channel.bans_unsynced.clear
      end
      @in_lists << :bans

      mask = msg.params[2]
      if @network == "jtv"
        # on the justin tv network, ban "masks" only consist of the
        # nick/username
        mask = "%s!%s@%s" % [mask, mask, mask + ".irc.justin.tv"]
      end

      if msg.params[3]
        by = User(msg.params[3].split("!").first)
      else
        by = nil
      end

      at   = Time.at(msg.params[4].to_i)
      ban = Ban.new(mask, by, at)
      msg.channel.bans_unsynced << ban
    end

    def on_368(msg, events)
      # RPL_ENDOFBANLIST
      if @in_lists.include?(:bans)
        @in_lists.delete :bans
      else
        # we never received a ban, yet an end of list => no bans
        msg.channel.bans_unsynced.clear
      end

      msg.channel.mark_as_synced(:bans)
    end

    def on_396(msg, events)
      # RPL_HOSTHIDDEN
      # note: designed for freenode
      User(msg.params[0]).sync(:host, msg.params[1], true)
    end

    def on_401(msg, events)
      # ERR_NOSUCHNICK
      user = User(msg.params[1])
      user.sync(:unknown?, true, true)
      if @whois_updates.key?(user)
        user.end_of_whois(nil, true)
        @whois_updates.delete user
      end
    end

    def on_402(msg, events)
      # ERR_NOSUCHSERVER

      if user = @bot.user_manager.find(msg.params[1]) # not _ensured, we only want a user that already exists
        user.end_of_whois(nil, true)
        @whois_updates.delete user
        # TODO freenode specific, test on other IRCd
      end
    end

    def on_433(msg, events)
      # ERR_NICKNAMEINUSE
      @bot.nick = @bot.generate_next_nick(msg.params[1])
    end

    def on_671(msg, events)
      user = User(msg.params[1])
      @whois_updates[user].merge!({:secure? => true})
    end
  end
end
