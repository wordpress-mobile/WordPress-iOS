source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods', '1.5.3'
  gem 'xcpretty-travis-formatter'
  gem 'danger'
  #gem 'danger-swiftlint'
  gem 'octokit', "~> 4.0"
  gem 'fastlane'
  gem 'dotenv'
end
gem 'danger-swiftlint' git: 'https://github.com/loremattei/danger-ruby-swiftlint', ref: 'd374409'

plugins_path = File.join(File.dirname(__FILE__), 'Scripts/fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
