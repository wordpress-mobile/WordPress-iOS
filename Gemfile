source 'https://rubygems.org'

gem 'rake'
gem 'cocoapods', '~> 1.11'
gem 'xcpretty-travis-formatter'
gem 'octokit', '~> 4.0'
gem 'fastlane', '~> 2.174'
gem 'dotenv'
gem 'commonmarker'
gem 'rubocop', '~> 1.30'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
