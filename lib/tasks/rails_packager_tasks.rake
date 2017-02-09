desc "Package this Rails project"
task :package, [:name] => :environment do |t, args|
  require "rails_packager"
  config_path = Rails.root.join(".rails-package")
  config_file = config_path if config_path.exist?
  runner = RailsPackager::Runner.new(config_file: config_file, dir: Rails.root, name: args[:name].presence)
  runner.execute(verbose: ENV["verbose"] == "true")
end
