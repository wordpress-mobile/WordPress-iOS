#!/bin/bash
chruby 2.3.1
bundle install
bundle exec danger --fail-on-errors=false
