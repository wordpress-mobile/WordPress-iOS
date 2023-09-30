# frozen_string_literal: true

source 'https://rubygems.org'

# 1.12.x and higher, starting from 1.12.1, because that hotfix fixes Xcode 14.3 compatibility
gem 'cocoapods', '~> 1.12', '>= 1.12.1'
gem 'commonmarker'
gem 'danger', '~> 9.3'
gem 'danger-rubocop', '~> 0.10'
gem 'dotenv'
gem 'fastlane', '~> 2.174'
gem 'fastlane-plugin-appcenter', '~> 1.8'
gem 'fastlane-plugin-sentry'
# This comment avoids typing to switch to a development version for testing.
#
# Switch to this branch for auto-retry on 429 for GlotPress strings while
# waiting for the fix to be shipped.
# gem 'fastlane-plugin-wpmreleasetoolkit', git: 'git@github.com:wordpress-mobile/release-toolkit', branch: 'mokagio/auto-retry-on-strings-glotpress-429'
#
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 9.1'
gem 'rake'
gem 'rubocop', '~> 1.30'
gem 'rubocop-rake', '~> 0.6'
gem 'xcpretty-travis-formatter'

group :screenshots, optional: true do
  gem 'rmagick', '~> 3.2.0'
end
