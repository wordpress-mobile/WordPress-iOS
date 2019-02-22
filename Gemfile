source 'https://rubygems.org' do
  gem 'rake', "12.3.2"
  gem 'cocoapods', '1.5.3'
  gem 'cocoapods-repo-update', '~> 0.0.3'
  gem 'xcpretty-travis-formatter'
  gem 'octokit', "~> 4.0"
  gem 'fastlane', "2.116.1"
  gem 'dotenv', "2.7.0"
  gem 'rubyzip', "~> 1.2.2"
end

plugins_path = File.join(File.dirname(__FILE__), 'Scripts/fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
