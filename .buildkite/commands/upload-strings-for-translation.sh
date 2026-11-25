#!/bin/bash -eu

# Regenerates the English strings from code and keeps the "Update strings for localization" PR up to date.
# Publishes only on trunk; any other branch is a dry run. See docs/localization-pipeline.md.

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

echo '--- :rubygems: Setting up Gems'
install_gems

echo '--- :globe_with_meridians: Regenerate strings for translation'
bundle exec fastlane upload_strings_for_translation
