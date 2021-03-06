$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_packager/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_packager"
  s.version     = RailsPackager::VERSION
  s.authors     = ["Mike Virata-Stone"]
  s.email       = ["mike@virata-stone.com"]
  s.homepage    = "https://github.com/on-site/rails_packager"
  s.summary     = "Rails engine to provide tools to package your application"
  s.description = "This is an exceedingly over-engineered gem that provides a way to package your Rails app in a gzipped file"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,exe,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.bindir      = "exe"
  s.executables = s.files.grep(%r{^exe/}) {|f| File.basename(f) }

  s.add_dependency "rails", ">= 4.0", "< 6.0"

  if RUBY_PLATFORM == "java"
    s.add_development_dependency "jdbc-sqlite3"
  else
    s.add_development_dependency "sqlite3"
  end
end
