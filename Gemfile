source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods', '~> 1.8.0'
  gem 'xcpretty-travis-formatter'
  gem 'octokit', "~> 4.0"
  gem 'fastlane', "2.151.2"
  gem 'dotenv'
  gem 'commonmarker'
end

plugins_path = File.join(File.dirname(__FILE__), 'Scripts/fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
