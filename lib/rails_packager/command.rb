module RailsPackager
  class Command
    attr_reader :name

    def initialize(name, *args, opts)
      @name = name
      @args = args
      @runner = opts.fetch(:runner)
      @dir = opts[:dir]
      @env = opts.fetch(:env, {})
    end

    def dir
      @dir || @runner.dir
    end

    def env
      @runner.env.merge(@env)
    end

    def args
      @args.map do |arg|
        result = arg.dup
        result["@{name}"] = @runner.name if result["@{name}"]
        raise "@{files} must be a singular argument" if result["@{files}"] && result != "@{files}"
        result = @runner.files if result == "@{files}"
        result
      end.flatten
    end

    def self.parse(runner, value)
      parsed = CommandParser.parse(value)
      new(parsed.name, *parsed.args, runner: runner, env: parsed.env)
    end
  end
end
