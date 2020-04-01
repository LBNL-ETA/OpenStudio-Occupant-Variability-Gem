source "http://rubygems.org"

allow_local = false

# Specify your gem's dependencies
gemspec

if allow_local && File.exists?('../OpenStudio-extension-gem')
  # gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else
  gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', tag: 'v0.1.1'
end

# if allow_local && File.exists?('../OpenStudio-Standards')
#   # gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
#   puts 'Use local version of OpenStudio-Standards'
#   gem 'openstudio-standards', path: '../OpenStudio-Standards'
# else
#   puts 'Use remote version of OpenStudio-Standards'
#   gem 'openstudio-standards', github: 'NREL/OpenStudio-Standards', tag: 'v0.2.9'
# end

gem 'openstudio_measure_tester', '= 0.1.7' # This includes the dependencies for running unit tests, coverage, and rubocop
#gem 'openstudio_measure_tester', :github => 'NREL/OpenStudio-measure-tester-gem', :ref => '273d1f1a5c739312688ea605ef4a5b6e7325332c'

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
gem 'simplecov', github: 'NREL/simplecov'
