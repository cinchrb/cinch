require "timeout"
require "net/protocol"
require "cinch/network"

module Cinch
  # This class manages the connection to the IRC server. That includes
  # processing incoming and outgoing messages, creating Ruby objects
  # and invoking plugins.
  class IRC
    include Helpers

    # @return [ISupport]
    attr_reader :isupport

    # @return [Bot]
    attr_reader :bot

    # @return [Network] The detected network
    attr_reader :network

    def initialize(bot)
      @bot      = bot
      @isupport = ISupport.new
    end

    # @return [TCPSocket]
    # @api private
    # @since 2.0.0
    def socket
      @socket.io
    end

    # @api private
    # @return [void]
    # @since 2.0.0
    def setup
      @registration  = []
      @network       = Network.new(:unknown, :unknown)
      @whois_updates = {}
      @in_lists      = Set.new
    end

    # @api private
    # @return [Boolean] True if the connection could be established
    def connect
      tcp_socket = nil

      begin
        Timeout::timeout(@bot.config.timeouts.connect) do
          tcp_socket = TCPSocket.new(@bot.config.server, @bot.config.port, @bot.config.local_host)
        end
      rescue Timeout::Error
        @bot.loggers.warn("Timed out while connecting")
        return false
      rescue SocketError => e
        @bot.loggers.warn("Could not connect to the IRC server. Please check your network: #{e.message}")
        return false
      rescue => e
        @bot.loggers.exception(e)
        return false
      end

      if @bot.config.ssl.use
        setup_ssl(tcp_socket)
      else
        @socket = tcp_socket
      end

      @socket              = Net::BufferedIO.new(@socket)
      @socket.read_timeout = @bot.config.timeouts.read
      @queue               = MessageQueue.new(@socket, @bot)

      return true
    end

    # @api private
    # @return [void]
    # @since 2.0.0
    def setup_ssl(socket)
      # require openssl in this method so the bot doesn't break for
      # people who don't have SSL but don't want to use SSL anyway.
      require 'openssl'

      ssl_context = OpenSSL::SSL::SSLContext.new

      if @bot.config.ssl.is_a?(Configuration::SSL)
        if @bot.config.ssl.client_cert
          ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(@bot.config.ssl.client_cert))
          ssl_context.key  = OpenSSL::PKey::RSA.new(File.read(@bot.config.ssl.client_cert))
        end

        ssl_context.ca_path     = @bot.config.ssl.ca_path
        ssl_context.verify_mode = @bot.config.ssl.verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      else
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @bot.loggers.info "Using SSL with #{@bot.config.server}:#{@bot.config.port}"

      @socket      = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
      @socket.sync = true
      @socket.connect
    end

    # @api private
    # @return [void]
    # @since 2.0.0
    def send_cap_ls
      send "CAP LS"
    end

    # @api private
    # @return [void]
    # @since 2.0.0
    def send_cap_req
      caps = [:"away-notify", :"multi-prefix", :sasl] & @network.capabilities

      # InspIRCd doesn't respond to empty REQs, so send an END in that
      # case.
      if caps.size > 0
        send "CAP REQ :" + caps.join(" ")
      else
        send_cap_end
      end
    end

    # @since 2.0.0
    # @api private
    # @return [void]
    def send_cap_end
      send "CAP END"
    end

    # @api private
    # @return [void]
    # @since 2.0.0
    def send_login
      send "PASS #{@bot.config.password}" if @bot.config.password
      send "NICK #{@bot.generate_next_nick!}"
      send "USER #{@bot.config.user} 0 * :#{@bot.config.realname}"
    end

    # @api private
    # @return [Thread] the reading thread
    # @since 2.0.0
    def start_reading_thread
      Thread.new do
        begin
          while line = @socket.readline
            rescue_exception do
              line = Cinch::Utilities::Encoding.encode_incoming(line, @bot.config.encoding)
              parse line
            end
          end
        rescue Timeout::Error
          @bot.loggers.warn "Connection timed out."
        rescue EOFError
          @bot.loggers.warn "Lost connection."
        rescue => e
          @bot.loggers.exception(e)
        end

        @socket.close
        @bot.handlers.dispatch(:disconnect)
        # FIXME won't we kill all :disconnect handlers here? prolly
        # not, as they have 10 seconds to finish. that should be
        # plenty of time
        @bot.handlers.stop_all
      end
    end

    # @api private
    # @return [Thread] the sending thread
    # @since 2.0.0
    def start_sending_thread
      Thread.new do
        rescue_exception do
          @queue.process!
        end
      end
    end

    # @api private
    # @return [Thread] The ping thread.
    # @since 2.0.0
    def start_ping_thread
      Thread.new do
        while true
          sleep @bot.config.ping_interval
          # PING requires a single argument. In our case the value
          # doesn't matter though.
          send("PING 0")
        end
      end
    end

    # @since 2.0.0
    def send_sasl
      if @bot.config.sasl.username && @sasl_current_method = @sasl_remaining_methods.pop
        @bot.loggers.info "[SASL] Trying to authenticate with #{@sasl_current_method.mechanism_name}"
        send "AUTHENTICATE #{@sasl_current_method.mechanism_name}"
      else
        send_cap_end
      end
    end

    # Establish a connection.
    #
    # @return [void]
    # @since 2.0.0
    def start
      setup
      if connect
        @sasl_remaining_methods = [SASL::Plain, SASL::DH_Blowfish]
        send_cap_ls
        send_login

        reading_thread = start_reading_thread
        sending_thread = start_sending_thread
        ping_thread    = start_ping_thread

        reading_thread.join
        sending_thread.kill
        ping_thread.kill
      end
    end

    # @api private
    # @return [void]
    def parse(input)
      return if input.chomp.empty?
      @bot.loggers.incoming(input)

      msg          = Message.new(input, @bot)
      events       = [[:catchall]]

      if ["001", "002", "003", "004", "422"].include?(msg.command)
        @registration << msg.command
        if registered?
          events << [:connect]
          @bot.last_connection_was_successful = true
          on_connect(msg, events)
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
          events << [:message]
        end

        if msg.action?
          events << [:action]
        end
      end

      meth = "on_#{msg.command.downcase}"
      __send__(meth, msg, events) if respond_to?(meth, true)

      if msg.error?
        events << [:error]
      end

      events << [msg.command.downcase.to_sym]

      msg.events = events.map(&:first)
      events.each do |event, *args|
        @bot.handlers.dispatch(event, msg, *args)
      end
    end

    # @return [Boolean] true if we successfully registered yet
    def registered?
      (("001".."004").to_a - @registration).empty? || @registration.include?("422")
    end

    # Send a message to the server.
    # @param [String] msg
    # @return [void]
    def send(msg)
      @queue.queue(msg)
    end

    private
    def set_leaving_user(message, user, events)
      events << [:leaving, user]
    end

    # @since 2.0.0
    def detect_network(msg, event)
      old_network = @network
      new_network = nil
      new_ircd    = nil
      case event
      when "002"
        if msg.params.last =~ /^Your host is .+?, running version (.+)$/
          case $1
          when /\+snircd\(/
            new_ircd = :snircd
          when /^u[\d\.]+$/
            new_ircd = :ircu
          when /^(.+?)-?\d+/
            new_ircd = $1.downcase.to_sym
          end
        elsif msg.params.last == "Your host is jtvchat"
          new_network = :jtv
          new_ircd    = :jtv
        end
      when "005"
        case @isupport["NETWORK"]
        when "NGameTV"
          new_network = :ngametv
          new_ircd    = :ngametv
        when nil
        else
          new_network = @isupport["NETWORK"].downcase.to_sym
        end
      end

      new_network ||= old_network.name
      new_ircd    ||= old_network.ircd

      if old_network.unknown_ircd? && new_ircd != :unknown
        @bot.loggers.info "Detected IRCd: #{new_ircd}"
      end
      if !old_network.unknown_ircd? && new_ircd != old_network.ircd
        @bot.loggers.info "Detected different IRCd: #{old_network.ircd} -> #{new_ircd}"
      end
      if old_network.unknown_network? && new_network != :unknown
        @bot.loggers.info "Detected network: #{new_network}"
      end
      if !old_network.unknown_network? && new_network != old_network.name
        @bot.loggers.info "Detected different network: #{old_network.name} -> #{new_network}"
      end

      @network.name = new_network
      @network.ircd = new_ircd
    end

    def process_ban_mode(msg, events, param, direction)
      mask = param
      ban = Ban.new(mask, msg.user, Time.now)

      if direction == :add
        msg.channel.bans_unsynced << ban
        events << [:ban, ban]
      else
        msg.channel.bans_unsynced.delete_if {|b| b.mask == ban.mask}.first
        events << [:unban, ban]
      end
    end

    def process_owner_mode(msg, events, param, direction)
      owner = User(param)
      if direction == :add
        msg.channel.owners_unsynced << owner unless msg.channel.owners_unsynced.include?(owner)
        events << [:owner, owner]
      else
        msg.channel.owners_unsynced.delete(owner)
        events << [:deowner, owner]
      end
    end

    def update_whois(user, data)
      @whois_updates[user] ||= {}
      @whois_updates[user].merge!(data)
    end

    # @since 2.0.0
    def on_away(msg, events)
      if msg.message.to_s.empty?
        # unaway
        msg.user.sync(:away, nil, true)
        events << [:unaway]
      else
        # away
        msg.user.sync(:away, msg.message, true)
        events << [:away]
      end
    end

    # @since 2.0.0
    def on_cap(msg, events)
      case msg.params[1]
      when "LS"
        @network.capabilities.concat msg.message.split(" ").map(&:to_sym)
        send_cap_req
      when "ACK"
        if @network.capabilities.include?(:sasl)
          send_sasl
        else
          send_cap_end
        end
      when "NAK"
        send_cap_end
      end
    end

    # @since 2.0.0
    def on_connect(msg, events)
      @bot.modes = @bot.config.modes
    end

    def on_join(msg, events)
      if msg.user == @bot
        @bot.channels << msg.channel
        msg.channel.sync_modes
      end
      msg.channel.add_user(msg.user)
      msg.user.online = true
    end

    def on_kick(msg, events)
      target = User(msg.params[1])
      if target == @bot
        @bot.channels.delete(msg.channel)
      end
      msg.channel.remove_user(target)

      set_leaving_user(msg, target, events)
    end

    def on_kill(msg, events)
      user = User(msg.params[1])

      @bot.channel_list.each do |channel|
        channel.remove_user(user)
      end

      user.unsync_all
      user.online = false

      set_leaving_user(msg, user, events)
    end

    # @version 1.1.0
    def on_mode(msg, events)
      if msg.channel?
        add_and_remove = @bot.irc.isupport["CHANMODES"]["A"] + @bot.irc.isupport["CHANMODES"]["B"] + @bot.irc.isupport["PREFIX"].keys

        param_modes = {
          :add    => @bot.irc.isupport["CHANMODES"]["C"] + add_and_remove,
          :remove => add_and_remove
        }

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
              process_ban_mode(msg, events, param, direction)
            when "q"
              process_owner_mode(msg, events, param, direction) if @network.owner_list_mode
            else
              raise Exceptions::UnsupportedMode, mode
            end
          else
            # channel options
            if direction == :add
              msg.channel.modes_unsynced[mode] = param.nil? ? true : param
            else
              msg.channel.modes_unsynced.delete(mode)
            end
          end
        end

        events << [:mode_change, modes]
      elsif msg.params.first == bot.nick
        modes = ModeParser.parse_modes(msg.params[1], msg.params[2..-1])
        modes.each do |direction, mode, _|
          if direction == :add
            @bot.modes << mode unless @bot.modes.include?(mode)
          else
            @bot.modes.delete(mode)
          end
        end
      end
    end

    def on_nick(msg, events)
      if msg.user == @bot
        # @bot.set_nick msg.params.last
        target = @bot
      else
        target = msg.user
      end

      target.update_nick(msg.params.last)
      target.online = true
    end

    def on_part(msg, events)
      msg.channel.remove_user(msg.user)
      msg.user.channels_unsynced.delete msg.channel

      if msg.user == @bot
        @bot.channels.delete(msg.channel)
      end

      set_leaving_user(msg, msg.user, events)
    end

    def on_ping(msg, events)
      send "PONG :#{msg.params.first}"
    end

    def on_topic(msg, events)
      msg.channel.sync(:topic, msg.params[1])
    end

    def on_quit(msg, events)
      @bot.channel_list.each do |channel|
        channel.remove_user(msg.user)
      end
      msg.user.unsync_all
      msg.user.online = false

      set_leaving_user(msg, msg.user, events)

      if msg.message.downcase == "excess flood" && msg.user == @bot
        @bot.warn ["Looks like your bot has been kicked because of excess flood.",
                   "If you haven't modified the throttling options manually, please file a bug report at https://github.com/cinchrb/cinch/issues and include the following information:",
                   "- Server: #{@bot.config.server}",
                   "- Messages per second: #{@bot.config.messages_per_second}",
                   "- Server queue size: #{@bot.config.server_queue_size}"]
      end
    end

    # @since 2.0.0
    def on_privmsg(msg, events)
      if msg.user
        msg.user.online = true
      end


      if msg.message =~ /^\001DCC SEND (?:"([^"]+)"|(\S+)) (\S+) (\d+)(?: (\d+))?\001$/
        process_dcc_send($1 || $2, $3, $4, $5, msg, events)
      end
    end

    # @since 2.0.0
    def process_dcc_send(filename, ip, port, size, m, events)
      if ip =~ /^\d+$/
        # If ip is a single integer, assume it's a specification
        # compliant IPv4 address in network byte order. If it's any
        # other string, assume that it's a valid IPv4 or IPv6 address.
        # If it's not valid, let someone higher up the chain notice
        # that.
        ip   = ip.to_i
        ip   = [24, 16, 8, 0].collect {|b| (ip >> b) & 255}.join('.')
      end

      port = port.to_i
      size = size.to_i

      @bot.loggers.info "DCC: Incoming DCC SEND: File name: %s - Size: %dB - IP: %s - Port: %d" % [filename, size, ip, port]

      dcc = DCC::Incoming::Send.new(user: m.user, filename: filename, size: size, ip: ip, port: port)
      events << [:dcc_send, dcc]
    end

    # @since 2.0.0
    def on_001(msg, events)
      # Ensure that we know our real, possibly truncated or otherwise
      # modified nick.
      @bot.set_nick msg.params.first
    end

    # @since 2.0.0
    def on_002(msg, events)
      detect_network(msg, "002")
    end

    def on_005(msg, events)
      # ISUPPORT
      @isupport.parse(*msg.params[1..-2].map {|v| v.split(" ")}.flatten)
      detect_network(msg, "005")
    end

    # @since 2.0.0
    def on_301(msg, events)
      # RPL_AWAY
      user = User(msg.params.first)
      away = msg.message

      if @whois_updates[user]
        update_whois(user, {:away => away})
      end
    end

    # @since 1.1.0
    def on_307(msg, events)
      # RPL_WHOISREGNICK
      user = User(msg.params[1])
      update_whois(user, {:authname => user.nick})
    end

    def on_311(msg, events)
      # RPL_WHOISUSER
      user = User(msg.params[1])
      update_whois(user, {
                     :user => msg.params[2],
                     :host => msg.params[3],
                     :realname => msg.params[5],
                   })
    end

    def on_313(msg, events)
      # RPL_WHOISOPERATOR
      user = User(msg.params[1])
      @whois_updates[user].merge!({:oper? => true})
    end

    def on_317(msg, events)
      # RPL_WHOISIDLE
      user = User(msg.params[1])
      update_whois(user, {
                     :idle => msg.params[2].to_i,
                     :signed_on_at => Time.at(msg.params[3].to_i),
                   })
    end

    def on_318(msg, events)
      # RPL_ENDOFWHOIS
      user = User(msg.params[1])

      if @whois_updates[user]
        if @whois_updates[user].empty? && !user.attr(:unknown?, true, true)
          user.end_of_whois(nil)
        else
          user.end_of_whois(@whois_updates[user])
        end
        @whois_updates.delete user
      end
    end

    def on_319(msg, events)
      # RPL_WHOISCHANNELS
      user     = User(msg.params[1])
      channels = msg.params[2].scan(/[#{@isupport["CHANTYPES"].join}][^ ]+/o).map {|c| Channel(c) }
      @whois_updates[user].merge!({:channels => channels})
    end

    def on_324(msg, events)
      # RPL_CHANNELMODEIS
      modes     = {}
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
      user     = User(msg.params[1])
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

    def on_352(msg, events)
      # RPL_WHOREPLY
      # "<channel> <user> <host> <server> <nick> <H|G>[*][@|+] :<hopcount> <real name>"
      _, channel, user, host, _, nick, _, hopsrealname = msg.params
      _, realname = hopsrealname.split(" ", 2)
      channel     = Channel(channel)
      user_object = User(nick)
      user_object.sync(:user, user, true)
      user_object.sync(:host, host, true)
      user_object.sync(:realname, realname, true)
    end

    def on_354(msg, events)
      # RPL_WHOSPCRPL
      # We are using the following format: %acfhnru

      #                          _         user      host                                 nick      f account  realame
      # :leguin.freenode.net 354 dominikh_ ~a        ip-88-152-125-117.unitymediagroup.de dominikh_ H 0        :d
      # :leguin.freenode.net 354 dominikh_ ~FiXato   fixato.net                           FiXato    H FiXato   :FiXato, using WeeChat -- More? See: http://twitter
      # :leguin.freenode.net 354 dominikh_ ~dominikh cinch/developer/dominikh             dominikh  H DominikH :dominikh
      # :leguin.freenode.net 354 dominikh_ ~oddmunds s21-04214.dsl.no.powertech.net       oddmunds  H 0        :oddmunds

      _, channel, user, host, nick, _, account, realname = msg.params
      channel = Channel(channel)
      user_object = User(nick)
      user_object.sync(:user, user, true)
      user_object.sync(:host, host, true)
      user_object.sync(:realname, realname, true)
      user_object.sync(:authname, account == "0" ? nil : account, true)
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
          prefixes = m[1].split("").map {|s| @isupport["PREFIX"].key(s)}
          nick   = user[prefixes.size..-1]
        else
          nick   = user
          prefixes = []
        end
        user        = User(nick)
        user.online = true
        msg.channel.add_user(user, prefixes)
        user.channels_unsynced << msg.channel unless user.channels_unsynced.include?(msg.channel)
      end
    end

    def on_366(msg, events)
      # RPL_ENDOFNAMES
      @in_lists.delete :names
      msg.channel.mark_as_synced(:users)
    end

    # @version 2.0.0
    def on_367(msg, events)
      # RPL_BANLIST
      unless @in_lists.include?(:bans)
        msg.channel.bans_unsynced.clear
      end
      @in_lists << :bans

      mask = msg.params[2]
      if @network.jtv?
        # on the justin tv network, ban "masks" only consist of the
        # nick/username
        mask = "%s!%s@%s" % [mask, mask, mask + ".irc.justin.tv"]
      end

      if msg.params[3]
        by = User(msg.params[3].split("!").first)
      else
        by = nil
      end

      at  = Time.at(msg.params[4].to_i)
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

    def on_386(msg, events)
      # RPL_QLIST
      unless @in_lists.include?(:owners)
        msg.channel.owners_unsynced.clear
      end
      @in_lists << :owners

      owner = User(msg.params[2])
      msg.channel.owners_unsynced << owner
    end

    def on_387(msg, events)
      # RPL_ENDOFQLIST
      if @in_lists.include?(:owners)
        @in_lists.delete :owners
      else
        #we never received an owner, yet an end of list -> no owners
        msg.channel.owners_unsynced.clear
      end

      msg.channel.mark_as_synced(:owners)
    end

    def on_396(msg, events)
      # RPL_HOSTHIDDEN
      # note: designed for freenode
      User(msg.params[0]).sync(:host, msg.params[1], true)
    end

    def on_401(msg, events)
      # ERR_NOSUCHNICK
      if user = @bot.user_list.find(msg.params[1])
        user.end_of_whois(nil, true)
        @whois_updates.delete user
      end
    end

    def on_402(msg, events)
      # ERR_NOSUCHSERVER

      if user = @bot.user_list.find(msg.params[1]) # not _ensured, we only want a user that already exists
        user.end_of_whois(nil, true)
        @whois_updates.delete user
        # TODO freenode specific, test on other IRCd
      end
    end

    def on_433(msg, events)
      # ERR_NICKNAMEINUSE
      @bot.nick = @bot.generate_next_nick!(msg.params[1])
    end

    def on_671(msg, events)
      user = User(msg.params[1])
      @whois_updates[user].merge!({:secure? => true})
    end

    # @since 2.0.0
    def on_730(msg, events)
      # RPL_MONONLINE
      msg.params.last.split(",").each do |mask|
        user = User(Mask.new(mask).nick)
        # User is responsible for emitting an event
        user.online = true
      end
    end

    # @since 2.0.0
    def on_731(msg, events)
      # RPL_MONOFFLINE
      msg.params.last.split(",").each do |nick|
        user = User(nick)
        # User is responsible for emitting an event
        user.online = false
      end
    end

    # @since 2.0.0
    def on_734(msg, events)
      # ERR_MONLISTFULL
      user = User(msg.params[2])
      user.monitored = false
    end

    # @since 2.0.0
    def on_903(msg, events)
      # SASL authentication successful
      @bot.loggers.info "[SASL] SASL authentication with #{@sasl_current_method.mechanism_name} successful"
      send_cap_end
    end

    # @since 2.0.0
    def on_904(msg, events)
      # SASL authentication failed
      @bot.loggers.info "[SASL] SASL authentication with #{@sasl_current_method.mechanism_name} failed"
      send_sasl
    end

    # @since 2.0.0
    def on_authenticate(msg, events)
      send "AUTHENTICATE " + @sasl_current_method.generate(@bot.config.sasl.username,
                                                           @bot.config.sasl.password,
                                                           msg.params.last)
    end
  end
end
