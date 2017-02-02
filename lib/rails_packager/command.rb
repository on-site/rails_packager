module RailsPackager
  class Command
    def self.replace_variables(runner, value, allow_files: false)
      result = value.dup
      result.gsub!(/\$\{(\w+)\}/) { |m| ENV.fetch($1, "") }
      result["@{name}"] = runner.name if result["@{name}"]

      if allow_files
        raise ArgumentError, "@{files} must be a singular argument" if result["@{files}"] && result != "@{files}"
        result = runner.files if result == "@{files}"
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

    private

    def replace_variables(value, allow_files: false)
      RailsPackager::Command.replace_variables(@runner, value, allow_files: allow_files)
    end
  end
end
