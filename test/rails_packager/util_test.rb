require "test_helper"

class RailsPackager::UtilTest < ActiveSupport::TestCase
  test "deep_freeze with a deeply nested object freezes everything" do
    object = RailsPackager::Util.deep_freeze(
      "string" => "hello world",
      "array" => [
        "first",
        { "second" => "is_hash" }
      ]
    )

    assert object.keys.all?(&:frozen?)
    assert object.values.all?(&:frozen?)
    assert object["string"].frozen?
    assert object["array"].all?(&:frozen?)
    assert object["array"].last.keys.all?(&:frozen?)
    assert object["array"].last.values.all?(&:frozen?)
  end

  test "glob_match? with an exact match" do
    assert RailsPackager::Util.glob_match?("some/testing.rb", "some/testing.rb")

    refute RailsPackager::Util.glob_match?("some/testing.rb", "some/other.rb")
    refute RailsPackager::Util.glob_match?("some/testing.rb", "other/testing.rb")
  end

  test "glob_match? with a file glob match" do
    assert RailsPackager::Util.glob_match?("some*.rb", "some_testing.rb")

    refute RailsPackager::Util.glob_match?("some*.rb", "some/testing.rb")
    refute RailsPackager::Util.glob_match?("some*.rb", "other_testing.rb")
    refute RailsPackager::Util.glob_match?("some*.rb", "other_some_testing.rb")
  end

  test "glob_match? with a directory glob match" do
    assert RailsPackager::Util.glob_match?("*/testing.rb", "some/testing.rb")
    assert RailsPackager::Util.glob_match?("*/testing.rb", "other/testing.rb")

    refute RailsPackager::Util.glob_match?("*/testing.rb", "some/other/testing.rb")
    refute RailsPackager::Util.glob_match?("*/testing.rb", "some/other.rb")
    refute RailsPackager::Util.glob_match?("*/testing.rb", "other/other.rb")
  end

  test "glob_match? with a recursive directory glob match" do
    assert RailsPackager::Util.glob_match?("**/testing.rb", "some/path/to/testing.rb")
    assert RailsPackager::Util.glob_match?("**/testing.rb", "other/testing.rb")
    assert RailsPackager::Util.glob_match?("**/testing.rb", "testing.rb")

    refute RailsPackager::Util.glob_match?("**/testing.rb", "some/other.rb")
    refute RailsPackager::Util.glob_match?("**/testing.rb", "other/path/to/other.rb")
  end

  test "glob_match? with a combined glob match" do
    assert RailsPackager::Util.glob_match?("**/*file.rb", "some/path/to/testing_file.rb")
    assert RailsPackager::Util.glob_match?("**/*file.rb", "some/path/to/file.rb")
    assert RailsPackager::Util.glob_match?("**/*file.rb", "file.rb")
    assert RailsPackager::Util.glob_match?("**/*file.rb", "some_file.rb")

    refute RailsPackager::Util.glob_match?("**/*file.rb", "some/path/to_something.rb")
    refute RailsPackager::Util.glob_match?("**/*file.rb", "some/path/file_something.rb")
  end

  test "glob_match? with a globbed dotfile" do
    assert RailsPackager::Util.glob_match?("*.rb", ".some.rb")
  end

  test "glob_match? with a parent directory match" do
    assert RailsPackager::Util.glob_match?("parent", "parent")
    assert RailsPackager::Util.glob_match?("parent", "parent/to/some/file.rb")

    refute RailsPackager::Util.glob_match?("parent", "some/parent/to/some/file.rb")
    refute RailsPackager::Util.glob_match?("parent", "parent_dir/to/some/file.rb")
  end

  test "glob_match? with a parent globbed directory match" do
    assert RailsPackager::Util.glob_match?("**/parent", "parent")
    assert RailsPackager::Util.glob_match?("**/parent", "some/parent")
    assert RailsPackager::Util.glob_match?("**/parent", "some/parent/to/some/file.rb")

    refute RailsPackager::Util.glob_match?("**/parent", "some/parent_dir/to/some/file.rb")
    refute RailsPackager::Util.glob_match?("**/parent", "some_parent/to/some/file.rb")
  end
end
