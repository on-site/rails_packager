module RailsPackager
  module UtilHelper
    def config_file(name)
      File.expand_path(File.join("../../files", name), __FILE__)
    end

    def strip_whitespace(str)
      spaces = str[/\A +/]
      str.gsub(/^#{spaces}/, "")
    end

    def new_runner(*options)
      @runner = RailsPackager::Runner.new(*options)
    end

    def close_runner
      @runner.close if defined?(@runner) && @runner
    end
  end
end
