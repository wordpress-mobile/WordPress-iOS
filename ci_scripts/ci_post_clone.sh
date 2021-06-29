#!/bin/sh

echo "~~~~ Ruby:"
ruby -v

echo "~~~~ RVM?"
which rvm

echo "~~~~ rbenv?"
which rbenv

# Can't sudo
# sudo gem install bundler:2.2.19

# Running this just for fun, it won't get us to use Bundler 2.x
bundle update --bundler

bundle install
bundle exec pod install
