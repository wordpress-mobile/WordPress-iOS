#!/bin/bash -eu

# FIXIT-13.1: Temporary fix until we're on the Xcode 13.1 VM
echo "--- :rubygems: Fixing Ruby Setup"
gem install bundler
