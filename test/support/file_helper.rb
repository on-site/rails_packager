module RailsPackager
  module FileHelper
    def config_file(name)
      File.expand_path(File.join("../../files", name), __FILE__)
    end

    def strip_whitespace(str)
      spaces = str[/\A +/]
      str.gsub(/^#{spaces}/, "")
    end
  end
end
