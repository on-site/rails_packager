require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
require "tempfile"
require "yaml"

module RailsPackager
  class Runner
    attr_reader :includes, :excludes, :env, :dir, :name, :before, :package, :after

    # This command is inserted after bundle install when jbundler usage is detected
    JBUNDLE_COMMAND = "jbundle install --vendor".freeze

    DEFAULT_CONFIG = RailsPackager::Util.deep_freeze(
      env: {},
      exclude: ["**/.git", "tmp"],
      before: [
        ["bundle install --deployment --without development test", {
           "unsetenv" => ["RUBYOPT", "RUBYLIB", "BUNDLER_ORIG_GEM_PATH", "BUNDLER_ORIG_PATH"],
           "env" => { "GEM_PATH" => "${BUNDLER_ORIG_GEM_PATH}" }
         }],
        "gem install bundler --install-dir vendor/bundle",
        ["bundle exec rake assets:precompile", {
           "unsetenv" => ["RUBYOPT", "RUBYLIB", "BUNDLER_ORIG_GEM_PATH", "BUNDLER_ORIG_PATH"],
           "env" => {
             "RAILS_ENV" => "production",
             "GEM_PATH" => "${BUNDLER_ORIG_GEM_PATH}"
           }
         }]
      ],
      package: "tar --no-recursion --files-from @{files_file} -zcvf @{name}.tar.gz"
    )

    def initialize(dir:, name: nil, config_file: nil)
      @files_file_tempfile = nil
      @dir = dir
      @name = name

      config =
        if config_file
          YAML.load_file(config_file)
        else
          {}
        end

      load_config(config)
    end

    def files
      result = Dir.glob(File.join(dir, "**/*"), File::FNM_DOTMATCH).map do |file|
        file.sub(File.join(dir, "/"), "")
      end

      # Drop special directory files
      result.reject! { |f| f =~ %r{/\.\.?\z} || f =~ /\A\.\.?\z/ }

      result.select! { |f| includes.any? { |i| RailsPackager::Util.glob_match?(i, f) } } if includes
      result.reject! { |f| excludes.any? { |e| RailsPackager::Util.glob_match?(e, f) } } if excludes
      result
    end

    def files_file
      @files_file_tempfile ||=
        begin
          Tempfile.new("rails_packager_file_names").tap do |tempfile|
            files.each { |f| tempfile.puts f }
            tempfile.close
          end
        end

      @files_file_tempfile.path
    end

    def commands
      before + [package] + after
    end

    def execute(verbose: false)
      commands.each { |cmd| break unless cmd.execute(verbose: verbose) }
    ensure
      close
    end

    def close
      if @files_file_tempfile
        @files_file_tempfile.unlink
        @files_file_tempfile = nil
      end
    end

    def successful?
      commands.all?(&:successful?)
    end

    def exit_code
      errored = commands.find { |cmd| !cmd.successful? }

      if errored
        errored.exit_code
      else
        0
      end
    end

    private

    def replace_variables(value)
      RailsPackager::Command.replace_variables(self, value)
    end

    def load_config(config)
      config = config.symbolize_keys
      customized_before = config.include?(:before)
      config = DEFAULT_CONFIG.merge(config)

      if !customized_before && jbundler_in_use?
        config[:before] = config[:before].dup
        config[:before].insert(2, JBUNDLE_COMMAND)
      end

      @includes = config[:include]
      @excludes = config[:exclude]

      @env = config[:env].inject({}) do |result, (key, value)|
        result[key] = replace_variables(value)
        result
      end

      @name = name.presence || replace_variables(config.fetch(:name) { File.basename(File.realpath(dir)) })
      @before = config.fetch(:before, []).map { |x| RailsPackager::Command.parse(self, x) }
      @after = config.fetch(:after, []).map { |x| RailsPackager::Command.parse(self, x) }
      @package = RailsPackager::Command.parse(self, config[:package])
    end

    def jbundler_in_use?
      File.exist? File.join(dir, "Jarfile")
    end
  end
end
