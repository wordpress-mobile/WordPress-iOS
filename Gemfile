source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods', '1.6.1'
  gem 'cocoapods-repo-update', '~> 0.0.3'
  gem 'xcpretty-travis-formatter'
  gem 'octokit', "~> 4.0"
  gem 'fastlane', "2.127.2"
  gem 'dotenv'
  gem 'rubyzip', "~> 1.2.2"
  gem 'commonmarker'
end

plugins_path = File.join(File.dirname(__FILE__), 'Scripts/fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
