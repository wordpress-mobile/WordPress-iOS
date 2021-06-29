#!/bin/sh

ruby -v

# Get the latest version of Bundler.
#
# Xcode Cloud ships with system ruby (2.6.3p69) Hopefully this is enough to get
#
# Bundler 2.x installed, which is what the repo tooling needs.
bundle update --bundler

bundle install
bundle exec pod install
