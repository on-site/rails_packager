require "yaml"

module RailsPackager
  class Runner
    attr_reader :includes, :excludes, :env, :dir, :name, :before, :package, :after

    DEFAULT_CONFIG = {
      env: {},
      exclude: ["**/.git".freeze].freeze,
      before: [
        [{ "RAILS_ENV".freeze => "production".freeze }, "bundle exec rake assets:precompile".freeze].freeze
      ],
      package: "tar --no-recursion -zcvf @{name}.tar.gz @{files}".freeze
    }.freeze

    def initialize(opts)
      @dir = opts.fetch(:dir)

      config =
        if opts[:config]
          YAML.load_file(opts[:config])
        else
          DEFAULT_CONFIG
        end

      load_config(config)
    end

    def files
      result = Dir.glob(File.join(dir, "**/*"), File::FNM_DOTMATCH).map do |file|
        file.sub(File.join(dir, "/"), "")
      end

      # Drop special directory files
      result.reject! { |f| f =~ %r{/\.\.?\z} || f =~ /\A\.\.?\z/ }

      result.select! { |f| includes.any? { |i| File.fnmatch(i, f, File::FNM_PATHNAME | File::FNM_DOTMATCH) } } if includes
      result.reject! { |f| excludes.any? { |e| File.fnmatch(e, f, File::FNM_PATHNAME | File::FNM_DOTMATCH) } } if excludes
      result
    end

    def commands
      before + [package] + after
    end

    private

    def load_config(config)
      config = DEFAULT_CONFIG.merge(config.symbolize_keys)
      @includes = config[:include]
      @excludes = config[:exclude]
      @env = config[:env]
      @name = config.fetch(:name) { File.basename(File.realpath(dir)) }
      @before = config.fetch(:before, []).map { |x| RailsPackager::Command.parse(self, x) }
      @after = config.fetch(:after, []).map { |x| RailsPackager::Command.parse(self, x) }
      @package = RailsPackager::Command.parse(self, config[:package])
    end
  end
end
