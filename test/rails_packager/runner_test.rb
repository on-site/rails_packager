require "test_helper"

class RailsPackager::RunnerTest < ActiveSupport::TestCase
  test "no customization" do
    runner = RailsPackager::Runner.new(dir: DUMMY_RAILS_DIR)
    assert_equal ["**/.git"], runner.excludes
    assert_equal nil, runner.includes
    assert_equal 2, runner.commands.size

    command = runner.commands[0]
    assert_equal({ "RAILS_ENV" => "production" }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "bundle", command.name
    assert_equal ["exec", "rake", "assets:precompile"], command.args

    command = runner.commands[1]
    assert_equal({}, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "tar", command.name
    assert_equal ["--no-recursion", "-zcvf", "dummy.tar.gz"], command.args.take(3)
    # Test a few files that should be included
    assert_includes command.args.drop(3), "log/.keep"
    assert_includes command.args.drop(3), "config/routes.rb"
    assert_includes command.args.drop(3), "app/controllers/application_controller.rb"

    # Includes directories
    assert_includes command.args.drop(3), "config"

    # Doesn't include special directories
    refute_includes command.args.drop(3), "config/."
    refute_includes command.args.drop(3), "config/.."
  end

  test "fully customized" do
  end

  test "customized with environment variable replacement" do
  end

  test "customized with quotes in command" do
  end

  test "invalid customization: @{files} is not its own argument" do
  end

  test "invalid customization: @{files} is within quotes" do
  end
end
