# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.14'
gem 'danger-dangermattic', '~> 1.1'
gem 'dotenv'
# 2.221.0 includes a fix for an ASC-interfacing bug
#
# See https://github.com/wordpress-mobile/WordPress-iOS/pull/23118#issuecomment-2173254418
# and https://github.com/fastlane/fastlane/pull/21995
gem 'fastlane', '~> 2.221'
gem 'fastlane-plugin-appcenter', '~> 2.1'
gem 'fastlane-plugin-sentry'
# This comment avoids typing to switch to a development version for testing.
#
# gem 'fastlane-plugin-wpmreleasetoolkit', git: 'https://github.com/wordpress-mobile/release-toolkit', ref: ''
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 12.0'
gem 'rake'
gem 'rubocop', '~> 1.60'
gem 'rubocop-rake', '~> 0.6'
gem 'xcpretty-travis-formatter'

group :screenshots, optional: true do
  gem 'rmagick', '~> 5.3.0'
end
