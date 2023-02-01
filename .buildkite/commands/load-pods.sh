#!/bin/bash -eu

echo "--- :rubygems: Set up Gems"
install_gems

echo "--- :cocoapods: Set up Pods and cache them if needed"
install_cocoapods
