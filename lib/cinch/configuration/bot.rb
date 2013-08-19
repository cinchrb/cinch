require "cinch/configuration"

module Cinch
  class Configuration
    # @since 2.0.0
    class Bot < Configuration
      KnownOptions = [:server, :port, :ssl, :password, :nick, :nicks,
                      :realname, :user, :messages_per_second, :server_queue_size,
                      :strictness, :message_split_start, :message_split_end,
                      :max_messages, :plugins, :channels, :encoding, :reconnect, :max_reconnect_delay,
                      :local_host, :timeouts, :ping_interval, :delay_joins, :dcc, :shared, :sasl]

      # (see Configuration.default_config)
      def self.default_config
        {
          :server => "localhost",
          :port   => 6667,
          :ssl    => Configuration::SSL.new,
          :password => nil,
          :nick   => "cinch",
          :nicks  => nil,
          :realname => "cinch",
          :user => "cinch",
          :modes => [],
          :messages_per_second => nil,
          :server_queue_size => nil,
          :strictness => :forgiving,
          :message_split_start => '... ',
          :message_split_end   => ' ...',
          :max_messages => nil,
          :plugins => Configuration::Plugins.new,
          :channels => [],
          :encoding => :irc,
          :reconnect => true,
          :max_reconnect_delay => 300,
          :local_host => nil,
          :timeouts => Configuration::Timeouts.new,
          :ping_interval => 120,
          :delay_joins => 0,
          :dcc => Configuration::DCC.new,
          :sasl => Configuration::SASL.new,
          :shared => {},
        }
      end
    end
  end
end
