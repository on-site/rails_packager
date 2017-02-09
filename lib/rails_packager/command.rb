require "active_support/core_ext/object/blank"

module RailsPackager
  class Command
    def self.replace_variables(runner, value, allow_files: false)
      return nil if value.nil?
      result = value.dup
      result.gsub!(/\$\{(\w+)\}/) { |m| ENV.fetch($1, "") }
      result["@{name}"] = runner.name if result["@{name}"]

      if allow_files
        raise ArgumentError, "@{files} must be a singular argument" if result["@{files}"] && result != "@{files}"
        raise ArgumentError, "@{files_file} must be a singular argument" if result["@{files_file}"] && result != "@{files_file}"

        if result == "@{files}"
          result = runner.files
        elsif result == "@{files_file}"
          result = runner.files_file
        end
      end

      result
    end

    def self.parse(runner, value)
      parsed = CommandParser.parse(value)
      new(parsed.name, *parsed.args, runner: runner, env: parsed.env)
    end

    def initialize(name, *args, runner:, env: {})
      @runner = runner
      @name = replace_variables(name)
      @args = args
      @env = env
    end

    def name
      raise ArgumentError, "Invalid command: empty command name is not valid" if @name.blank?
      @name
    end

    def dir
      @runner.dir
    end

    def env
      @runner.env.merge(@env).inject({}) do |result, (key, value)|
        result[key] = replace_variables(value)
        result
      end
    end

    def args
      @args.map do |arg|
        replace_variables(arg, allow_files: true)
      end.flatten
    end

    def execute(verbose: false)
      command_name = name
      command_args = args
      command_line = ([command_name] + command_args).join(" ")
      puts "$ #{command_line}" if verbose
      system(env, command_name, *command_args, chdir: dir)
      @status = $?
      STDERR.puts "ERROR: '#{command_line}' returned error code: #{exit_code}" unless successful?
      successful?
    end

    def exit_code
      @status.exitstatus
    end

    def successful?
      @status.success?
    end

    private

    def replace_variables(value, allow_files: false)
      RailsPackager::Command.replace_variables(@runner, value, allow_files: allow_files)
    end
  end
end
