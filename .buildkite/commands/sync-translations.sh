#!/bin/bash -eu

# Downloads the latest translations from GlotPress, AI-backfills any strings
# still untranslated, and opens/updates a single PR to trunk. Runs daily.
#
# Requires ANTHROPIC_API_KEY in the CI environment for the AI backfill.
# Part of the "Faster Releases" RFC, Phase 2 (continuous translations).

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :globe_with_meridians: Sync translations'
bundle exec fastlane sync_translations
