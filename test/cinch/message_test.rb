context "A message" do
  context "coming from a server" do
    setup { Cinch::Message.new(":localhost message", Bot) }
    asserts(:server)
    asserts(:prefix).equals("localhost")
  end

  context "coming from a user" do
    setup { Cinch::Message.new(":nick!user@host message", Bot) }
    asserts(:server).nil
    asserts(:prefix).equals("nick!user@host")
    asserts("User#nick") { topic.user.nick }.equals("nick")
    asserts("User") { topic.user.class }.equals(Cinch::User)
  end

  context "with a command" do
    setup { Cinch::Message.new(":nick!user@host COMMAND", Bot) }
    asserts(:command).equals("COMMAND")
    asserts(:error?).equals(false)
    asserts(:error).nil
    asserts(:regular_command?)
    asserts(:ctcp?).equals(false)

    context "and arguments" do
      setup { Cinch::Message.new(":nick!user@host COMMAND arg1 arg2", Bot) }
      asserts(:params).equals(["arg1", "arg2"])
      asserts(:message).equals("arg2")
      asserts(:ctcp?).equals(false)

      context "and a message" do
        setup { Cinch::Message.new(":nick!user@host COMMAND arg1 arg2 :message with a : colon", Bot) }
        asserts(:params).equals(["arg1", "arg2", "message with a : colon"])
        asserts(:message).equals("message with a : colon")
        asserts(:ctcp?).equals(false)
      end
    end

    context "and a message" do
      setup { Cinch::Message.new(":nick!user@host COMMAND :message with a : colon", Bot) }
      asserts(:params).equals(["message with a : colon"])
      asserts(:message).equals("message with a : colon")
      asserts(:ctcp?).equals(false)
    end
  end

  context "describing an error" do
    setup { Cinch::Message.new(":localhost 433 * nick :Nickname is already in use.", Bot) }
    asserts(:numeric_reply?)
    asserts(:error?)
    asserts(:error).equals(433)
    asserts(:params).equals(["*", "nick", "Nickname is already in use."])
    asserts(:message).equals("Nickname is already in use.")
  end

  context "describing a numeric reply" do
    setup { Cinch::Message.new(":localhost 001 cinch :Welcome to the Internet Relay Chat Network cinch", Bot) }
    asserts(:numeric_reply?)
    asserts(:command).equals("001")
    asserts(:params).equals(["cinch", "Welcome to the Internet Relay Chat Network cinch"])
    asserts(:message).equals("Welcome to the Internet Relay Chat Network cinch")
  end

  context "in a channel" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG #channel :a message", Bot) }
    asserts(:channel?)
    asserts("Channel") { topic.channel.class }.equals(Cinch::Channel)
    asserts("Channel#name") { topic.channel.name }.equals("#channel")
    asserts(:ctcp?).equals(false)
    asserts("can be replied to, without a prefix") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.reply "reply message"
      topic.bot.raw_log.last == "PRIVMSG #channel :reply message"
    }
    asserts("can be replied to, with a prefix") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.reply "reply message", true
      topic.bot.raw_log.last == "PRIVMSG #channel :nick: reply message"
    }
    asserts("can be safe-replied to, without a prefix") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.safe_reply "reply message\000"
      topic.bot.raw_log.last == "PRIVMSG #channel :reply message"
    }
    asserts("can be safe-replied to, with a prefix") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.safe_reply "reply message\000", true
      topic.bot.raw_log.last == "PRIVMSG #channel :nick: reply message"
    }
  end

  context "in private" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG user :a message", Bot) }
    asserts(:channel?).equals(false)
    asserts(:ctcp?).equals(false)
    asserts("can be replied to, without a prefix") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.reply "reply message"
      topic.bot.raw_log.last == "PRIVMSG nick :reply message"
    }
    asserts("can be replied to, but a prefix will be ignored") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.reply "reply message", true
      topic.bot.raw_log.last == "PRIVMSG nick :reply message"
    }
    asserts("can be safe-replied to, without a prefix") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.safe_reply "reply message\000"
      topic.bot.raw_log.last == "PRIVMSG nick :reply message"
    }
    asserts("can be safe-replied to, but a prefix will be ignored") {
      user = Bot.user_manager.find_ensured("cinch")
      mock(user).user.returns "cinch"
      mock(user).host.returns "cinchrb.org"
      topic.safe_reply "reply message\000", true
      topic.bot.raw_log.last == "PRIVMSG nick :reply message"
    }
  end

  context "describing a CTCP message" do
    setup { Cinch::Message.new(":nick!user@host PRIVMSG cinch :\001PING\001", Bot) }
    asserts(:ctcp?)
    asserts(:ctcp_command).equals("PING")
    asserts(:ctcp_message).equals("PING")
    asserts(:ctcp_args).equals([])
    asserts("can be replied to") {
      topic.ctcp_reply("42")
      topic.bot.raw_log.last == "NOTICE nick :\001PING 42\001"
    }

    context "with parameters" do
      setup { Cinch::Message.new(":nick!user@host NOTICE cinch :\001PING 123 456\001", Bot) }
      asserts(:ctcp?)
      asserts(:ctcp_command).equals("PING")
      asserts(:ctcp_message).equals("PING 123 456")
      asserts(:ctcp_args).equals(["123", "456"])
    end
  end
end
