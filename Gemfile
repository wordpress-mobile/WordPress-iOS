source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods'
  gem 'xcpretty-travis-formatter'
  gem 'octokit', "~> 4.0"
  gem 'fastlane', "2.146.0"
  gem 'dotenv'
  gem 'rubyzip', "~> 1.3"
  gem 'commonmarker'
end

plugins_path = File.join(File.dirname(__FILE__), 'Scripts/fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
