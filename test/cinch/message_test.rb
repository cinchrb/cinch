context "A message" do
  context "coming from a server" do
    setup { Cinch::Message.new(":localhost message", Cinch::Bot.new) }
    asserts(:server)
    asserts(:prefix).equals("localhost")
  end

  context "coming from a user" do
    setup { Cinch::Message.new(":nick!user@host message", Cinch::Bot.new) }
    asserts(:server).nil
    asserts(:prefix).equals("nick!user@host")
    asserts("User#nick") { topic.user.nick }.equals("nick")
    asserts("User#user") { topic.user.user }.equals("user")
    asserts("User#host") { topic.user.host }.equals("host")
    asserts("User") { topic.user.class }.equals(Cinch::User)
  end

  context "with a command" do
    setup { Cinch::Message.new(":nick!user@host COMMAND", Cinch::Bot.new) }
    asserts(:command).equals("COMMAND")
    asserts(:error?).equals(false)
    asserts(:error).nil
    asserts(:regular_command?)
    asserts(:ctcp?).equals(false)

    context "and arguments" do
      setup { Cinch::Message.new(":nick!user@host COMMAND arg1 arg2", Cinch::Bot.new) }
      asserts(:params).equals(["arg1", "arg2"])
      asserts(:message).nil
      asserts(:ctcp?).equals(false)

      context "and a message" do
        setup { Cinch::Message.new(":nick!user@host COMMAND arg1 arg2 :message with a : colon", Cinch::Bot.new) }
        asserts(:params).equals(["arg1", "arg2", "message with a : colon"])
        asserts(:message).equals("message with a : colon")
        asserts(:ctcp?).equals(false)
      end
    end

    context "and a message" do
      setup { Cinch::Message.new(":nick!user@host COMMAND :message with a : colon", Cinch::Bot.new) }
      asserts(:params).equals(["message with a : colon"])
      asserts(:message).equals("message with a : colon")
      asserts(:ctcp?).equals(false)
    end
  end

  context "describing an error" do
    setup { Cinch::Message.new(":localhost 433 * nick :Nickname is already in use.", Cinch::Bot.new) }
    asserts(:numeric_reply?)
    asserts(:error?)
    asserts(:error).equals(433)
    asserts(:params).equals(["*", "nick", "Nickname is already in use."])
    asserts(:message).equals("Nickname is already in use.")
  end

  context "describing a numeric reply" do
    setup { Cinch::Message.new(":localhost 001 cinch :Welcome to the Internet Relay Chat Network cinch", Cinch::Bot.new) }
    asserts(:numeric_reply?)
    asserts(:command).equals("001")
    asserts(:params).equals(["cinch", "Welcome to the Internet Relay Chat Network cinch"])
    asserts(:message).equals("Welcome to the Internet Relay Chat Network cinch")
  end

  context "in a channel" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG #channel :a message", Cinch::Bot.new) }
    asserts(:channel?)
    asserts("Channel") { topic.channel.class }.equals(Cinch::Channel)
    asserts("Channel#name") { topic.channel.name }.equals("#channel")
    asserts(:ctcp?).equals(false)
  end

  context "in private" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG user :a message", Cinch::Bot.new) }
    asserts(:channel?).equals(false)
    asserts(:ctcp?).equals(false)
  end

  context "describing a CTCP message" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG cinch :\001PING\001", Cinch::Bot.new) }
    asserts(:ctcp?)
    asserts(:ctcp_command).equals("PING")
    asserts(:ctcp_message).equals("PING")
    asserts(:ctcp_args).equals([])

    context "with parameters" do
      setup { Cinch::Message.new(":nick!user@host NOTICE cinch :\001PING 123 456\001", Cinch::Bot.new) }
      asserts(:ctcp?)
      asserts(:ctcp_command).equals("PING")
      asserts(:ctcp_message).equals("PING 123 456")
      asserts(:ctcp_args).equals(["123", "456"])
    end
  end
end
