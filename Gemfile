# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.14'
gem 'commonmarker'
gem 'danger-dangermattic', git: 'https://github.com/Automattic/dangermattic'
gem 'dotenv'
# 2.219.0 includes a fix for a bug introduced in 2.218.0
# See https://github.com/fastlane/fastlane/issues/21762#issuecomment-1875208663
gem 'fastlane', '~> 2.219'
gem 'fastlane-plugin-appcenter', '~> 2.1'
gem 'fastlane-plugin-sentry'
# This comment avoids typing to switch to a development version for testing.
#
# Attempt to address 'Bad CPU type in executable' on new Apple Silicon CI
# See https://buildkite.com/automattic/wordpress-ios/builds/19609#018ced25-05f4-4c8b-9850-b314ea2f8d9e/1131-1330
# gem 'fastlane-plugin-wpmreleasetoolkit', git: 'https://github.com/wordpress-mobile/release-toolkit', ref: '2cb009edaee3d058a61cfeb503e533eb0647f108'
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 9.3'
gem 'rake'
gem 'rubocop', '~> 1.30'
gem 'rubocop-rake', '~> 0.6'
gem 'xcpretty-travis-formatter'

group :screenshots, optional: true do
  gem 'rmagick', '~> 3.2.0'
end
