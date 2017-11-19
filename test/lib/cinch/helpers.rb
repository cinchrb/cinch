require "helper"

class HelperTest < TestCase
  test "Sanitize should remove newlines" do
    assert_equal "ab", Cinch::Helpers.sanitize("a\r\nb")
  end
end

