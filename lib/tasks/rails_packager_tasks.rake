desc "Package this Rails project"
task package: :environment do
  require "rails_packager"
  config_path = Rails.root.join(".rails-package")
  config_file = config_path if config_path.exist?
  runner = RailsPackager::Runner.new(config_file: config_file, dir: Rails.root)
  runner.execute
end
