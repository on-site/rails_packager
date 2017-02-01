module RailsPackager
  class Command
    attr_reader :name, :env

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

    def args
      @args.map do |arg|
        result = arg.dup
        result["@{name}"] = @runner.name if result["@{name}"]
        raise "@{files} must be a singular argument" if result["@{files}"] && result != "@{files}"
        result = @runner.files if result == "@{files}"
        result
      end.flatten
    end

    def self.precompile_assets(runner)
      new("bundle", "exec", "rake", "assets:precompile", runner: runner, env: { "RAILS_ENV" => "production" })
    end

    def self.tarball(runner)
      new("tar", "--no-recursion", "-zcvf", "@{name}.tar.gz", "@{files}", runner: runner, env: {})
    end
  end
end
