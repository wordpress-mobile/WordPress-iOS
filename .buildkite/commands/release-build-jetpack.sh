#!/bin/bash -eu

echo "--- :arrow_down: Installing Release Dependencies"
# Disabled to hopefully work past the failure seen in
# https://buildkite.com/automattic/wordpress-ios/builds/12513#01865ef3-8a38-4303-b028-bead44ee943d
#
# ==> Installing python@3.11
# ==> Pouring python@3.11--3.11.2.monterey.bottle.1.tar.gz
# Error: The `brew link` step did not complete successfully
# The formula built, but is not symlinked into /usr/local
# Could not symlink bin/2to3
# Target /usr/local/bin/2to3
# is a symlink belonging to python@3.10. You can unlink it:
#   brew unlink python@3.10
#
# To force the link and overwrite all conflicting files:
#   brew link --overwrite python@3.11
#
# To list all files that would be deleted:
#   brew link --overwrite --dry-run python@3.11
#
# Possible conflicting files are:
# /usr/local/bin/2to3 -> /usr/local/Cellar/python@3.10/3.10.9/bin/2to3
# /usr/local/bin/idle3 -> /usr/local/Cellar/python@3.10/3.10.9/bin/idle3
# /usr/local/bin/pydoc3 -> /usr/local/Cellar/python@3.10/3.10.9/bin/pydoc3
# /usr/local/bin/python3 -> /usr/local/Cellar/python@3.10/3.10.9/bin/python3
# /usr/local/bin/python3-config -> /usr/local/Cellar/python@3.10/3.10.9/bin/python3-config
# /usr/local/share/man/man1/python3.1 -> /usr/local/Cellar/python@3.10/3.10.9/share/man/man1/python3.1
# /usr/local/lib/pkgconfig/python3-embed.pc -> /usr/local/Cellar/python@3.10/3.10.9/lib/pkgconfig/python3-embed.pc
# /usr/local/lib/pkgconfig/python3.pc -> /usr/local/Cellar/python@3.10/3.10.9/lib/pkgconfig/python3.pc
# /usr/local/Frameworks/Python.framework/Headers -> /usr/local/Cellar/python@3.10/3.10.9/Frameworks/Python.framework/Headers
# /usr/local/Frameworks/Python.framework/Python -> /usr/local/Cellar/python@3.10/3.10.9/Frameworks/Python.framework/Python
# /usr/local/Frameworks/Python.framework/Resources -> /usr/local/Cellar/python@3.10/3.10.9/Frameworks/Python.framework/Resources
# /usr/local/Frameworks/Python.framework/Versions/Current -> /usr/local/Cellar/python@3.10/3.10.9/Frameworks/Python.framework/Versions/Current
#
# brew update # Update homebrew to temporarily fix a bintray issue
brew install imagemagick
brew install ghostscript
brew upgrade sentry-cli

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- :closed_lock_with_key: Installing Secrets"
bundle exec fastlane run configure_apply

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_and_upload_jetpack_for_app_store
