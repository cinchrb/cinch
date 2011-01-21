# -*- coding: utf-8 -*-
require "thread"

module Cinch
  # @api private
  class MessageQueue
    def initialize(socket, bot)
      @socket               = socket
      @queue                = Queue.new
      @time_since_last_send = nil
      @bot                  = bot

      @log = []
    end

    # @return [void]
    def queue(message)
      command = message.split(" ").first

      if command == "PONG"
        @queue.unshift(message)
      else
        @queue << message
      end
    end

    # @return [void]
    def process!
      while true
        mps            = @bot.config.messages_per_second
        max_queue_size = @bot.config.server_queue_size

        if @log.size > 1
          time_passed = 0

          @log.each_with_index do |one, index|
            second = @log[index+1]
            time_passed += second - one
            break if index == @log.size - 2
          end

          messages_processed = (time_passed * mps).floor
          effective_size = @log.size - messages_processed

          if effective_size <= 0
            @log.clear
          elsif effective_size >= max_queue_size
            sleep 1.0/mps
          end
        end

        message = @queue.pop.to_s.chomp

        begin
          @socket.writeline Cinch.encode_outgoing(message, @bot.config.encoding) + "\r\n"
          @log << Time.now
          @bot.logger.log(message, :outgoing) if @bot.config.verbose

          @time_since_last_send = Time.now
        rescue IOError
          @bot.debug "Could not send message (connectivity problems): #{message}"
        end
      end
    end
  end
end
