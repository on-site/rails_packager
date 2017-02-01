require "test_helper"

class RailsPackager::RunnerTest < ActiveSupport::TestCase
  include RailsPackager::FileHelper

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
    assert_equal ["--no-recursion", "-zcvf", "dummy.tar.gz", *runner.files], command.args

    # Test a few files that should be included
    assert_includes runner.files, "log/.keep"
    assert_includes runner.files, "config/routes.rb"
    assert_includes runner.files, "app/controllers/application_controller.rb"

    # Includes directories
    assert_includes runner.files, "config"

    # Doesn't include special directories
    refute_includes runner.files, "config/."
    refute_includes runner.files, "config/.."
  end

  test "fully customized" do
    runner = RailsPackager::Runner.new(config: config_file("fully-customized.yml"), dir: DUMMY_RAILS_DIR)
    assert_equal ["log/**/*"], runner.excludes
    assert_equal nil, runner.includes
    assert_equal 5, runner.commands.size

    command = runner.commands[0]
    assert_equal({ "EXAMPLE" => "first env var", "EXAMPLE_2" => "second env var" }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "echo", command.name
    assert_equal ["this", "is", "before", "-", "packaged-0.0.1-SNAPSHOT"], command.args

    command = runner.commands[1]
    assert_equal({ "EXAMPLE" => "first env var", "EXAMPLE_2" => "second env var" }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "echo", command.name
    assert_equal ["this", "is", "also", "before"], command.args

    command = runner.commands[2]
    assert_equal({ "EXAMPLE" => "first env var", "EXAMPLE_2" => "second env var" }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "echo", command.name
    assert_equal ["packaged-0.0.1-SNAPSHOT.tar.gz", *runner.files], command.args

    command = runner.commands[3]
    assert_equal({ "EXAMPLE" => "first env var", "EXAMPLE_2" => "second env var" }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "echo", command.name
    assert_equal ["this", "is", "after", "-", "packaged-0.0.1-SNAPSHOT"], command.args

    command = runner.commands[4]
    assert_equal({ "EXAMPLE" => "first env var", "EXAMPLE_2" => "second env var" }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "echo", command.name
    assert_equal ["this", "is", "also", "after", *runner.files], command.args

    # Test a few files that should be included
    assert_includes runner.files, "config/routes.rb"
    assert_includes runner.files, "app/controllers/application_controller.rb"

    # Includes directories
    assert_includes runner.files, "config"

    # Doesn't include special directories
    refute_includes runner.files, "config/."
    refute_includes runner.files, "config/.."

    # Doesn't include excluded files
    refute_includes runner.files, "log/.keep"
  end

  test "customized with environment variable in one command" do
  end

  test "customized with environment variable in one command merges with env" do
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
