require "cinch/configuration"

module Cinch
  class BotConfiguration < Configuration
    KnownOptions = [:server, :port, :ssl, :password, :nick, :nicks,
                    :realname, :user, :verbose, :messages_per_second, :server_queue_size,
                    :strictness, :message_split_start, :message_split_end,
                    :max_messages, :plugins, :channels, :encoding, :reconnect,
                    :local_host, :timeouts, :ping_interval]

    def self.default_config
      {
          :server => "localhost",
          :port   => 6667,
          :ssl    => SSLConfiguration.new,
          :password => nil,
          :nick   => "cinch",
          :nicks  => nil,
          :realname => "cinch",
          :user => "cinch",
          :verbose => true,
          :messages_per_second => 0.5,
          :server_queue_size => 10,
          :strictness => :forgiving,
          :message_split_start => '... ',
          :message_split_end   => ' ...',
          :max_messages => nil,
          :plugins => PluginsConfiguration.new,
          :channels => [],
          :encoding => :irc,
          :reconnect => true,
          :local_host => nil,
          :timeouts => TimeoutsConfiguration.new,
          :ping_interval => 120,
        }
    end
  end
end
