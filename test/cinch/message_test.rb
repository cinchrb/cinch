context "A message" do
  context "coming from a server" do
    setup { Cinch::Message.new(":localhost message", TestBot.new) }
    asserts(:server)
    asserts(:prefix).equals("localhost")
  end

  context "coming from a user" do
    setup { Cinch::Message.new(":nick!user@host message", TestBot.new) }
    asserts(:server).nil
    asserts(:prefix).equals("nick!user@host")
    asserts("User#nick") { topic.user.nick }.equals("nick")
    asserts("User") { topic.user.class }.equals(Cinch::User)
  end

  context "with a command" do
    setup { Cinch::Message.new(":nick!user@host COMMAND", TestBot.new) }
    asserts(:command).equals("COMMAND")
    asserts(:error?).equals(false)
    asserts(:error).nil
    asserts(:regular_command?)
    asserts(:ctcp?).equals(false)

    context "and arguments" do
      setup { Cinch::Message.new(":nick!user@host COMMAND arg1 arg2", TestBot.new) }
      asserts(:params).equals(["arg1", "arg2"])
      asserts(:message).nil
      asserts(:ctcp?).equals(false)

      context "and a message" do
        setup { Cinch::Message.new(":nick!user@host COMMAND arg1 arg2 :message with a : colon", TestBot.new) }
        asserts(:params).equals(["arg1", "arg2", "message with a : colon"])
        asserts(:message).equals("message with a : colon")
        asserts(:ctcp?).equals(false)
      end
    end

    context "and a message" do
      setup { Cinch::Message.new(":nick!user@host COMMAND :message with a : colon", TestBot.new) }
      asserts(:params).equals(["message with a : colon"])
      asserts(:message).equals("message with a : colon")
      asserts(:ctcp?).equals(false)
    end
  end

  context "describing an error" do
    setup { Cinch::Message.new(":localhost 433 * nick :Nickname is already in use.", TestBot.new) }
    asserts(:numeric_reply?)
    asserts(:error?)
    asserts(:error).equals(433)
    asserts(:params).equals(["*", "nick", "Nickname is already in use."])
    asserts(:message).equals("Nickname is already in use.")
  end

  context "describing a numeric reply" do
    setup { Cinch::Message.new(":localhost 001 cinch :Welcome to the Internet Relay Chat Network cinch", TestBot.new) }
    asserts(:numeric_reply?)
    asserts(:command).equals("001")
    asserts(:params).equals(["cinch", "Welcome to the Internet Relay Chat Network cinch"])
    asserts(:message).equals("Welcome to the Internet Relay Chat Network cinch")
  end

  context "in a channel" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG #channel :a message", TestBot.new) }
    asserts(:channel?)
    asserts("Channel") { topic.channel.class }.equals(Cinch::Channel)
    asserts("Channel#name") { topic.channel.name }.equals("#channel")
    asserts(:ctcp?).equals(false)
  end

  context "in private" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG user :a message", TestBot.new) }
    asserts(:channel?).equals(false)
    asserts(:ctcp?).equals(false)
  end

  context "describing a CTCP message" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG cinch :\001PING\001", TestBot.new) }
    asserts(:ctcp?)
    asserts(:ctcp_command).equals("PING")
    asserts(:ctcp_message).equals("PING")
    asserts(:ctcp_args).equals([])
    asserts("can be replied to") {
      topic.ctcp_reply("42")
      topic.bot.raw_log.last == "NOTICE nick :\001PING 42\001"
    }

    context "with parameters" do
      setup { Cinch::Message.new(":nick!user@host NOTICE cinch :\001PING 123 456\001", TestBot.new) }
      asserts(:ctcp?)
      asserts(:ctcp_command).equals("PING")
      asserts(:ctcp_message).equals("PING 123 456")
      asserts(:ctcp_args).equals(["123", "456"])
    end
  end
end
