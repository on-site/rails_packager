require "test_helper"

class RailsPackager::RunnerTest < ActiveSupport::TestCase
  include RailsPackager::UtilHelper
  teardown { close_runner }

  test "no customization" do
    runner = new_runner(dir: DUMMY_RAILS_DIR)
    assert_equal ["**/.git", "tmp"], runner.excludes
    assert_nil runner.includes
    assert_equal 4, runner.commands.size

    command = runner.commands[0]
    assert_equal({ "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLER_ORIG_GEM_PATH" => nil, "BUNDLER_ORIG_PATH" => nil, "GEM_PATH" => ENV["BUNDLER_ORIG_GEM_PATH"] }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "bundle", command.name
    assert_equal ["install", "--deployment", "--without", "development", "test"], command.args

    command = runner.commands[1]
    assert_equal({}, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "gem", command.name
    assert_equal ["install", "bundler", "--install-dir", "vendor/bundle"], command.args

    command = runner.commands[2]
    assert_equal({ "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLER_ORIG_GEM_PATH" => nil, "BUNDLER_ORIG_PATH" => nil, "RAILS_ENV" => "production", "GEM_PATH" => ENV["BUNDLER_ORIG_GEM_PATH"] }, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "bundle", command.name
    assert_equal ["exec", "rake", "assets:precompile"], command.args

    command = runner.commands[3]
    assert_equal({}, command.env)
    assert_equal DUMMY_RAILS_DIR, command.dir
    assert_equal "tar", command.name
    assert_equal ["--no-recursion", "--files-from", runner.files_file, "-zcvf", "dummy.tar.gz"], command.args
    assert_equal File.read(runner.files_file), runner.files.join("\n") + "\n"

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

  test "no customization with jbundler" do
    runner = new_runner(dir: DUMMY_JRUBY_RAILS_DIR)
    assert_equal ["**/.git", "tmp"], runner.excludes
    assert_nil runner.includes
    assert_equal 5, runner.commands.size

    command = runner.commands[0]
    assert_equal({ "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLER_ORIG_GEM_PATH" => nil, "BUNDLER_ORIG_PATH" => nil, "GEM_PATH" => ENV["BUNDLER_ORIG_GEM_PATH"] }, command.env)
    assert_equal DUMMY_JRUBY_RAILS_DIR, command.dir
    assert_equal "bundle", command.name
    assert_equal ["install", "--deployment", "--without", "development", "test"], command.args

    command = runner.commands[1]
    assert_equal({}, command.env)
    assert_equal DUMMY_JRUBY_RAILS_DIR, command.dir
    assert_equal "gem", command.name
    assert_equal ["install", "bundler", "--install-dir", "vendor/bundle"], command.args

    command = runner.commands[2]
    assert_equal({}, command.env)
    assert_equal DUMMY_JRUBY_RAILS_DIR, command.dir
    assert_equal "jbundle", command.name
    assert_equal ["install", "--vendor"], command.args

    command = runner.commands[3]
    assert_equal({ "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLER_ORIG_GEM_PATH" => nil, "BUNDLER_ORIG_PATH" => nil, "RAILS_ENV" => "production", "GEM_PATH" => ENV["BUNDLER_ORIG_GEM_PATH"] }, command.env)
    assert_equal DUMMY_JRUBY_RAILS_DIR, command.dir
    assert_equal "bundle", command.name
    assert_equal ["exec", "rake", "assets:precompile"], command.args

    command = runner.commands[4]
    assert_equal({}, command.env)
    assert_equal DUMMY_JRUBY_RAILS_DIR, command.dir
    assert_equal "tar", command.name
    assert_equal ["--no-recursion", "--files-from", runner.files_file, "-zcvf", "jruby_dummy.tar.gz"], command.args
    assert_equal File.read(runner.files_file), runner.files.join("\n") + "\n"

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
    runner = new_runner(config_file: config_file("fully-customized.yml"), dir: DUMMY_RAILS_DIR)
    assert_equal ["log/**/*"], runner.excludes
    assert_nil runner.includes
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

  test "environment variable in one command" do
    runner = new_runner(config_file: config_file("environment-variable-in-one-command.yml"), dir: DUMMY_RAILS_DIR)

    command = runner.commands[0]
    assert_equal({ "ENV_VAR" => "env value" }, command.env)
    assert_equal "command", command.name
    assert_equal ["with_env"], command.args

    command = runner.commands[1]
    assert_equal({}, command.env)
    assert_equal "command", command.name
    assert_equal ["without_env"], command.args
  end

  test "environment variable in one command merges with env" do
    runner = new_runner(config_file: config_file("environment-variable-in-one-command-merges-with-env.yml"), dir: DUMMY_RAILS_DIR)

    command = runner.commands[0]
    assert_equal({ "EXAMPLE" => "value", "ENV_VAR" => "env value", "OTHER" => "other value" }, command.env)
    assert_equal "command", command.name
    assert_equal ["with_env"], command.args

    command = runner.commands[1]
    assert_equal({ "EXAMPLE" => "value", "ENV_VAR" => "will be overridden" }, command.env)
    assert_equal "command", command.name
    assert_equal ["without_env"], command.args
  end

  test "environment variable replacement" do
    ENV["NAME_ENV"] = "name-value"
    ENV["ENV_VALUE"] = "env-value"
    ENV["OTHER_ENV_VALUE"] = "other-env-value"
    ENV["COMMAND_VALUE"] = "some-command"
    ENV["ARGUMENT_VALUE"] = "argument value"

    runner = new_runner(config_file: config_file("environment-variable-replacement.yml"), dir: DUMMY_RAILS_DIR)
    assert_equal "name-name-value", runner.name
    assert_equal({ "EXAMPLE" => "env env-value" }, runner.env)

    command = runner.commands[0]
    assert_equal({ "EXAMPLE" => "env env-value", "OTHER_EXAMPLE" => "env other-env-value" }, command.env)
    assert_equal "some-command", command.name
    assert_equal ["and", "argument value", "and", "missing--between"], command.args
  end

  test "missing command name" do
    ENV["EMPTY_COMMAND_NAME"] = ""
    runner = new_runner(config_file: config_file("missing-command-name.yml"), dir: DUMMY_RAILS_DIR)

    assert_raises(ArgumentError) { runner.commands[0].name }
    assert_raises(ArgumentError) { runner.commands[1].name }
    assert_raises(ArgumentError) { runner.commands[2].name }
  end

  test "quotes in command" do
    runner = new_runner(config_file: config_file("quotes-in-command.yml"), dir: DUMMY_RAILS_DIR)

    command = runner.commands[0]
    assert_equal "/bin/whenever however/whatever", command.name
    assert_equal ["some", %(arguments "listed"), "with", "quotes"], command.args
  end

  test "@{files} not its own argument" do
    assert_raises(ArgumentError) do
      runner = new_runner(config_file: config_file("files-not-its-own-argument.yml"), dir: DUMMY_RAILS_DIR)
      runner.commands[0].args
    end
  end

  test "@{files} is within quotes" do
    runner = new_runner(config_file: config_file("files-is-within-quotes.yml"), dir: DUMMY_RAILS_DIR)
    assert_raises(ArgumentError) { runner.commands[0].args }
  end
end
