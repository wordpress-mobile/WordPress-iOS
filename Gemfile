# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.11'
gem 'commonmarker'
gem 'danger', '~> 8.6'
gem 'danger-rubocop', '~> 0.10'
gem 'dotenv'
gem 'fastlane', :git => 'https://github.com/crazytonyli/fastlane.git', :branch => 'install-wwdr-g3'
gem 'octokit', '~> 4.0'
gem 'rake'
gem 'rubocop', '~> 1.30'
gem 'rubocop-rake', '~> 0.6'
gem 'xcpretty-travis-formatter'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
