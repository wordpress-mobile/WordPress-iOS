#!/bin/sh

ruby -v

gem install bundler # Is Bundler already available?
bundle install
bundle exec pod install
