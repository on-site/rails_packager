require "rails_packager/engine" if defined?(Rails)

module RailsPackager
  autoload :Command,       "rails_packager/command"
  autoload :CommandParser, "rails_packager/command_parser"
  autoload :Runner,        "rails_packager/runner"
  autoload :Util,          "rails_packager/util"
end
