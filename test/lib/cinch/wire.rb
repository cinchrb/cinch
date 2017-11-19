require "helper"

class WireTest < TestCase
  def setup
    @bot = Cinch::Bot.new do
      self.loggers.clear
      @irc = Cinch::IRC.new(self)
      @irc.setup
      @name = "cinch"
      # stub these so that they work without a real server connection
      def user
        "test"
      end
      def host
        "testhost"
      end
    end
    # put a StringIO in place of a socket
    @io = StringIO.new
    @bot.irc.instance_variable_set(:@socket, @io)
    @queue = Cinch::MessageQueue.new(@io, @bot)
    @bot.irc.instance_variable_set(:@queue, @queue)
    @to_process = @queue.instance_variable_get(:@queues_to_process)
  end

  # return all the data sent over the wire
  def sent
    while !@to_process.empty?
      @queue.__send__(:process_one)
    end
    @io.rewind
    @io.read
  end

  test "should be able to inspect sent IRC commands in tests" do
    @bot.send("hello,")
    @bot.send("world!")
    assert_equal "PRIVMSG cinch :hello,\r\nPRIVMSG cinch :world!\r\n", sent
  end

  test "should not be able to inject IRC commands using newlines in actions" do
    @bot.action("evil\r\nKICK #testchan John :Injecting commands")
    assert_equal "PRIVMSG cinch :\001ACTION evil\001\r\n", sent
  end

end

