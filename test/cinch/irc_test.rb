context "IRC" do
  setup {
    @fake_socket = FakeSocket.new
    @queue = FakeMessageQueue.new
    irc = Cinch::IRC.new(Bot)

    irc.setup
    irc.instance_variable_set(:@socket, @fake_socket)
    irc.instance_variable_set(:@queue, @queue)
    irc.start_reading_thread

    # irc.start_sending_thread

    irc
  }

  context("knows when registration finished") do
    denies("is registered before any message has been received") {
      @fake_socket.__wait_until_empty
      topic.registered?
    }

    denies("is registered if only one welcome message has been received") {
      @fake_socket.__write(":sender 001 cinch :Welcome")
      @fake_socket.__wait_until_empty
      topic.registered?
    }

    denies("is registered if only two welcome messages have been received") {
      @fake_socket.__write(":sender 002 cinch :Welcome")
      @fake_socket.__wait_until_empty
      topic.registered?
    }

    denies("is registered if only three welcome messages have been received") {
      @fake_socket.__write(":sender 003 cinch :Welcome")
      @fake_socket.__wait_until_empty
      topic.registered?
    }

    denies("is registered if four random messages have been received") {
      @fake_socket.__write(":sender 123 cinch :Welcome")
      @fake_socket.__write(":sender 321 cinch :Welcome")
      @fake_socket.__write(":sender 213 cinch :Welcome")
      @fake_socket.__write(":sender 312 cinch :Welcome")
      @fake_socket.__wait_until_empty
      topic.registered?
    }

    asserts("is registered if all four welcome messages have been received") {
      @fake_socket.__write(":sender 004 cinch :Welcome")
      @fake_socket.__wait_until_empty
      topic.registered?
    }
  end

  asserts("can send messages") {
    topic.message("test message")
    @queue.messages.pop == "test message"
  }
end
