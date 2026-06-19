#!/bin/bash -eu

# Regenerates the English `Localizable.strings` from code and pushes it to trunk
# so GlotPress imports new strings promptly. Runs on each trunk merge.
#
# Part of the "Faster Releases" RFC, Phase 2 (continuous translations).

echo '--- :robot_face: Use bot for Git operations'
source use-bot-for-git

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo '--- :closed_lock_with_key: Access secrets'
bundle exec fastlane run configure_apply

echo '--- :globe_with_meridians: Regenerate and upload strings for translation'
bundle exec fastlane upload_strings_for_translation
