# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.14'
gem 'commonmarker'
gem 'danger-dangermattic', git: 'https://github.com/Automattic/dangermattic'
gem 'dotenv'
gem 'fastlane', '~> 2.216'
gem 'fastlane-plugin-appcenter', '~> 2.1'
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
