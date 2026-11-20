#!/bin/bash -eu

# Downloads the latest human translations from GlotPress and keeps the "Update translations" PR up to date.
# Publishes only on trunk; any other branch is a dry run. See docs/localization-pipeline.md.

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

echo '--- :rubygems: Setting up Gems'
install_gems

echo '--- :globe_with_meridians: Sync translations'
bundle exec fastlane sync_translations
