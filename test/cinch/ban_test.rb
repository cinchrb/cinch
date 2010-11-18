context "A ban" do
  setup { Cinch::Ban.new("cinchy!cinch@cinchrb.org", nil, Time.now) }
  asserts("is not extended") { not topic.extended }
  should("match a User with a matching mask") { topic.match test_user }
  should("not match a User with a mismatching mask") { not topic.match(test_user("not_cinchy!cinch@cinchrb.org")) }
  asserts(:to_s).equals("cinchy!cinch@cinchrb.org")
  
  context "with wildcards" do
    setup { Cinch::Ban.new("*!*@cinchrb.org", nil, Time.now) }
    should("match a User with a matching mask") { topic.match test_user }
    should("not match a User with a mismatching mask") { not topic.match(test_user("someone!someone@localhost")) }
  end
end

context "An extended ban" do
  setup { Cinch::Ban.new("$r:Lee*", nil, Time.now) }
  asserts(:extended)
end
