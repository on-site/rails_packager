require "test_helper"

class RailsPackager::CommandParserTest < ActiveSupport::TestCase
  test "simple command" do
    parsed = RailsPackager::CommandParser.parse("cmd")
    assert_equal({}, parsed.env)
    assert_equal "cmd", parsed.name
    assert_equal [], parsed.args
  end

  test "command with env" do
    parsed = RailsPackager::CommandParser.parse(["cmd", { "env" => { "ENV_VAR" => "value" } }])
    assert_equal({ "ENV_VAR" => "value" }, parsed.env)
    assert_equal "cmd", parsed.name
    assert_equal [], parsed.args
  end

  test "command with unsetenv" do
    parsed = RailsPackager::CommandParser.parse(["cmd", { "unsetenv" => ["ENV_VAR"] }])
    assert_equal({ "ENV_VAR" => nil }, parsed.env)
    assert_equal "cmd", parsed.name
    assert_equal [], parsed.args
  end

  test "command with env and unsetenv" do
    parsed = RailsPackager::CommandParser.parse(["cmd", { "unsetenv" => ["ENV_VAR", "OTHER_ENV_VAR"], "env" => { "ENV_VAR" => "value" } }])
    assert_equal({ "ENV_VAR" => "value", "OTHER_ENV_VAR" => nil }, parsed.env)
    assert_equal "cmd", parsed.name
    assert_equal [], parsed.args
  end

  test "command with arguments" do
    parsed = RailsPackager::CommandParser.parse("echo some value")
    assert_equal({}, parsed.env)
    assert_equal "echo", parsed.name
    assert_equal ["some", "value"], parsed.args
  end

  test "command with arguments separated by multiple spaces" do
    parsed = RailsPackager::CommandParser.parse("echo  some     value")
    assert_equal({}, parsed.env)
    assert_equal "echo", parsed.name
    assert_equal ["some", "value"], parsed.args
  end

  test "command with single quoted arguments" do
    parsed = RailsPackager::CommandParser.parse("echo 'some quoted value'")
    assert_equal({}, parsed.env)
    assert_equal "echo", parsed.name
    assert_equal ["some quoted value"], parsed.args
  end

  test "command with double quoted arguments" do
    parsed = RailsPackager::CommandParser.parse(%(echo "some quoted value"))
    assert_equal({}, parsed.env)
    assert_equal "echo", parsed.name
    assert_equal ["some quoted value"], parsed.args
  end

  test "command with nested quoted arguments" do
    parsed = RailsPackager::CommandParser.parse(%(echo "some user's value" 'and "another" quoted value'))
    assert_equal({}, parsed.env)
    assert_equal "echo", parsed.name
    assert_equal ["some user's value", %(and "another" quoted value)], parsed.args
  end

  test "empty command" do
    assert_raises(ArgumentError) { RailsPackager::CommandParser.parse("") }
  end

  test "command with mismatched quotes" do
    assert_raises(ArgumentError) { RailsPackager::CommandParser.parse("echo 'mismatched quotes") }
  end
end
