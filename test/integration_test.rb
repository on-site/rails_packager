require "test_helper"

class IntegrationTest < ActiveSupport::TestCase
  include RailsPackager::UtilHelper
  teardown { close_runner }

  test "execution path" do
    runner = new_runner(config_file: config_file("execution-path.yml"), dir: DUMMY_RAILS_DIR)

    out, err = capture_subprocess_io do
      runner.execute
    end

    assert_equal strip_whitespace(<<-END), out
      #{DUMMY_RAILS_DIR}
      Packaging
    END
    assert_equal "", err
    assert runner.successful?
  end

  test "simple integration" do
    runner = new_runner(config_file: config_file("simple-integration.yml"), dir: DUMMY_RAILS_DIR)

    out, err = capture_subprocess_io do
      runner.execute
    end

    assert_equal strip_whitespace(<<-END), out
      Before one
      Before two
      Packaging
      After one
      After two
    END
    assert_equal "", err
    assert runner.successful?
  end

  test "simple integration with verbose" do
    runner = new_runner(config_file: config_file("simple-integration.yml"), dir: DUMMY_RAILS_DIR)

    out, err = capture_subprocess_io do
      runner.execute(verbose: true)
    end

    assert_equal strip_whitespace(<<-END), out
      $ echo Before one
      Before one
      $ echo Before two
      Before two
      $ echo Packaging
      Packaging
      $ echo After one
      After one
      $ echo After two
      After two
    END
    assert_equal "", err
    assert runner.successful?
  end

  test "integration from rails project" do
    out, err = capture_subprocess_io do
      system "cd '#{DUMMY_RAILS_DIR}' && rake package"
    end

    status = $?

    assert_equal strip_whitespace(<<-END), out
      Before one
      Before two
      Packaging dummy
      After one
      After two
    END
    assert_equal "", err
    assert status.success?
  end

  test "debug with rake task" do
    out, err = capture_subprocess_io do
      system "cd '#{DUMMY_RAILS_DIR}' && rake package verbose=true"
    end

    status = $?

    assert_equal strip_whitespace(<<-END), out
      $ echo Before one
      Before one
      $ echo Before two
      Before two
      $ echo Packaging dummy
      Packaging dummy
      $ echo After one
      After one
      $ echo After two
      After two
    END
    assert_equal "", err
    assert status.success?
  end

  test "change name with rake task" do
    out, err = capture_subprocess_io do
      system "cd '#{DUMMY_RAILS_DIR}' && rake package[customized-1.0.0]"
    end

    status = $?

    assert_equal strip_whitespace(<<-END), out
      Before one
      Before two
      Packaging customized-1.0.0
      After one
      After two
    END
    assert_equal "", err
    assert status.success?
  end

  test "integration from rails project with program form" do
    out, err = capture_subprocess_io do
      system "cd '#{DUMMY_RAILS_DIR}' && rails_package"
    end

    status = $?

    assert_equal strip_whitespace(<<-END), out
      Before one
      Before two
      Packaging dummy
      After one
      After two
    END
    assert_equal "", err
    assert status.success?
  end

  test "program form with debug output" do
    out, err = capture_subprocess_io do
      system "cd '#{DUMMY_RAILS_DIR}' && rails_package -v"
    end

    status = $?

    assert_equal strip_whitespace(<<-END), out
      $ echo Before one
      Before one
      $ echo Before two
      Before two
      $ echo Packaging dummy
      Packaging dummy
      $ echo After one
      After one
      $ echo After two
      After two
    END
    assert_equal "", err
    assert status.success?
  end

  test "program form with customized name output" do
    out, err = capture_subprocess_io do
      system "cd '#{DUMMY_RAILS_DIR}' && rails_package --name customized-1.0.0"
    end

    status = $?

    assert_equal strip_whitespace(<<-END), out
      Before one
      Before two
      Packaging customized-1.0.0
      After one
      After two
    END
    assert_equal "", err
    assert status.success?
  end

  test "failure integration" do
    runner = new_runner(config_file: config_file("failure-integration.yml"), dir: DUMMY_RAILS_DIR)

    out, err = capture_subprocess_io do
      runner.execute
    end

    failed_command = runner.commands[1]

    assert_equal strip_whitespace(<<-END), out
      Before one
    END
    assert_equal strip_whitespace(<<-END), err
      ERROR: 'false' returned error code: #{failed_command.exit_code}
    END

    assert_kind_of Integer, failed_command.exit_code
    refute_equal 0, failed_command.exit_code
    refute runner.successful?
  end

  test "failure integration with verbose" do
    runner = new_runner(config_file: config_file("failure-integration.yml"), dir: DUMMY_RAILS_DIR)

    out, err = capture_subprocess_io do
      runner.execute(verbose: true)
    end

    failed_command = runner.commands[1]

    assert_equal strip_whitespace(<<-END), out
      $ echo Before one
      Before one
      $ false
    END
    assert_equal strip_whitespace(<<-END), err
      ERROR: 'false' returned error code: #{failed_command.exit_code}
    END

    assert_kind_of Integer, failed_command.exit_code
    refute_equal 0, failed_command.exit_code
    refute runner.successful?
  end
end
