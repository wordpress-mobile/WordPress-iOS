#!/bin/sh

ruby -v

sudo gem install bundler:2.2.19

bundle install
bundle exec pod install
