# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.14'
gem 'commonmarker'
gem 'danger-dangermattic', git: 'https://github.com/Automattic/dangermattic'
gem 'dotenv'
# 2.217.0 includes a fix for Xcode 15 test results parsing in CI
gem 'fastlane', '~> 2.217'
gem 'fastlane-plugin-appcenter', '~> 2.1'
gem 'fastlane-plugin-sentry'
# This comment avoids typing to switch to a development version for testing.
#
# Attempt to address 'Bad CPU type in executable' on new Apple Silicon CI
# See https://buildkite.com/automattic/wordpress-ios/builds/19609#018ced25-05f4-4c8b-9850-b314ea2f8d9e/1131-1330
gem 'fastlane-plugin-wpmreleasetoolkit', git: 'git@github.com:wordpress-mobile/release-toolkit', ref: '2cb009edaee3d058a61cfeb503e533eb0647f108'
# gem 'fastlane-plugin-wpmreleasetoolkit', '~> 9.1'
gem 'rake'
gem 'rubocop', '~> 1.30'
gem 'rubocop-rake', '~> 0.6'
gem 'xcpretty-travis-formatter'

group :screenshots, optional: true do
  gem 'rmagick', '~> 3.2.0'
end
