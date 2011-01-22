context "A mask" do
  test_mask = "cinchy!cinch@cinchrb.org"

  setup { Cinch::Mask.new(test_mask) }
  asserts(:nick).equals("cinchy")
  asserts(:user).equals("cinch")
  asserts(:host).equals("cinchrb.org")
  asserts(:mask).equals(test_mask)
  asserts(:to_s).equals(test_mask)
  asserts("#to_s returns a *copy* of the stored mask") { topic.to_s.object_id != topic.mask && topic.to_s == topic.mask}
  should("be checkable for equality using #==") { topic == topic.dup }
  should("match a User with a matching mask") { topic.match(test_user) }
  should("not match a User with a mismatching mask") { not topic.match(test_user("not_cinchy!cinch@cinchrb.org")) }
  should("match a matching Mask") { topic.match(test_user.mask) }
  should("not match a mismatching Mask") { not topic.match(Cinch::Mask.new("not_cinchy!cinch@cinchrb.org")) }
  should("match a mask in String form") { topic.match(test_user.mask.to_s) }
  should("not match a mismatching mask in String form") { not topic.match("not_cinchy!cinch@cinchrb.org") }
  should("be able to be created from a String") { Cinch::Mask.from(test_mask) == Cinch::Mask.new(test_mask) }
  should("be able to be created from a Mask") { Cinch::Mask.from(topic) == topic }
  should("be able to be created from a User") { Cinch::Mask.from(test_user) == topic }

  should("be able to be created from a Ban") {
    ban = Cinch::Ban.new(test_mask, nil, Time.now)
    Cinch::Mask.from(ban) == topic
  }

  should("not be able to be created from any other object")

  context "with wildcards" do
    setup { Cinch::Mask.new("someon?!*@cinchrb.org") }
    should("match a User with a matching mask") { topic.match(test_user("someone!someone@cinchrb.org")) }
    should("not match a User with a mismatching mask") { not topic.match(test_user("someone!someone@localhost")) }
    should("match a matching Mask") { topic.match(Cinch::Mask.new("someone!someone@cinchrb.org")) }
    should("not match a mismatching Mask") { not topic.match(Cinch::Mask.new("someone!someone@localhost")) }
    should("match a mask in String form") { topic.match("someone!someone@cinchrb.org") }
    should("not match a mismatching mask in String form") { not topic.match("someone!someone@localhost") }
  end
end
