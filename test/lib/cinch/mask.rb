require "helper"

class MaskTest < TestCase
  DefaultMask = "foo*!bar?@baz"
  def setup
    @mask = Cinch::Mask.new(DefaultMask.dup)
  end
  test "Two equal masks should be equal" do
    mask2 = Cinch::Mask.new(DefaultMask.dup)

    assert @mask == mask2
    assert @mask.eql?(mask2)
  end

  test "A Mask's hash should depend on the mask" do
    mask2 = Cinch::Mask.new(DefaultMask.dup)

    assert_equal @mask.hash, mask2.hash
  end

  test "A Mask should match a User only if it has matching attributes" do
    user = Cinch::User.new("foo", nil)
    user2 = Cinch::User.new("foobar", nil)
    user3 = Cinch::User.new("barfoo", nil)

    # bar? -> bar, baz -> baz
    user.end_of_whois(user: "bar", host: "baz")
    assert @mask.match(user)

    # bar? -> bar2, baz -> baz
    user.end_of_whois(user: "bar2", host: "baz")
    assert @mask.match(user)

    # bar? !-> bar22, baz -> baz
    user.end_of_whois(user: "bar22", host: "baz")
    assert !@mask.match(user)

    # bar? -> bar, baz !-> meow
    user.end_of_whois(user: "bar", host: "meow")
    assert !@mask.match(user)

    # foo* -> foobar
    user2.end_of_whois(user: "bar", host: "baz")
    assert @mask.match(user2)

    # foo* !-> barfoo
    user3.end_of_whois(user: "bar", host: "baz")
    assert !@mask.match(user3)
  end

  test "A mask's string representation should equal the original mask string" do
    assert_equal DefaultMask.dup, @mask.to_s
  end

  test "A Mask can be created from Strings" do
    assert_equal @mask, Cinch::Mask.from(DefaultMask.dup)
  end

  test "A Mask can be created from objects that have a mask" do
    mask = Cinch::Mask.new("foo!bar@baz")
    user = Cinch::User.new("foo", nil)
    user.end_of_whois(user: "bar", host: "baz")
    new_mask = Cinch::Mask.from(user)

    assert_equal mask, new_mask
  end
end
