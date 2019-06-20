require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# Load in the rake tasks from the base openstudio-extension gem
require 'openstudio/extension/rake_task'
require 'openstudio/occupant_variability'
os_extension = OpenStudio::Extension::RakeTask.new
os_extension.set_extension_class(OpenStudio::OccupantVariability::OccupantVariability)


# User defined tasks
desc 'Try to run some tests'
task :run_test do
  puts 'This is a test rake task...'
  name = 'Occupancy Simulator Test...'

  puts name

end

task :run_all => [:run_test]


task default: :run_all