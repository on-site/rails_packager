module RailsPackager
  class Runner
    attr_reader :includes, :excludes, :dir, :name, :before, :package, :after

    def initialize(opts)
      @includes = nil
      @excludes = ["**/.git"]
      @dir = opts.fetch(:dir)
      @name = File.basename File.realpath(dir)
      @before = [
        RailsPackager::Command.precompile_assets(self)
      ]
      @package = RailsPackager::Command.tarball(self)
      @after = []
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
  end
end
