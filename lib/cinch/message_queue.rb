# -*- coding: utf-8 -*-
require "cinch/open_ended_queue"

module Cinch
  # This class manages all outgoing messages, applying rate throttling
  # and fair distribution.
  #
  # @api private
  class MessageQueue
    def initialize(socket, bot)
      @socket               = socket
      @queues               = {:generic => OpenEndedQueue.new}

      @queues_to_process    = Queue.new
      @queued_queues        = Set.new

      @mutex                = Mutex.new
      @time_since_last_send = nil
      @bot                  = bot

      @log = []
    end

    # @return [void]
    def queue(message)
      command, *rest = message.split(" ")

      queue = nil
      case command
      when "PRIVMSG", "NOTICE"
        @mutex.synchronize do
          # we are assuming that each message has only one target,
          # which will be true as long as the user does not send raw
          # messages.
          #
          # this assumption is also reflected in the computation of
          # passed time and processed messages, since our score does
          # not take weights into account.
          queue = @queues[rest.first] ||= OpenEndedQueue.new
        end
      else
        queue = @queues[:generic]
      end
      queue << message

      @mutex.synchronize do
        unless @queued_queues.include?(queue)
          @queued_queues << queue
          @queues_to_process << queue
        end
      end
    end

    # @return [void]
    def process!
      while true
        wait

        queue = @queues_to_process.pop
        message = queue.pop.to_s.chomp

        if queue.empty?
          @mutex.synchronize do
            @queued_queues.delete(queue)
          end
        else
          @queues_to_process << queue
        end

        begin
          to_send = Cinch::Utilities::Encoding.encode_outgoing(message, @bot.config.encoding)
          @socket.write to_send + "\r\n"
          @log << Time.now
          @bot.loggers.outgoing(message)

          @time_since_last_send = Time.now
        rescue IOError
          @bot.loggers.error "Could not send message (connectivity problems): #{message}"
        end
      end
    end

    private
    def wait
      mps            = @bot.config.messages_per_second || @bot.irc.network.default_messages_per_second
      max_queue_size = @bot.config.server_queue_size   || @bot.irc.network.default_server_queue_size

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
    end
  end
end
