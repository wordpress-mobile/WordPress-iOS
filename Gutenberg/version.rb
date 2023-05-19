# frozen_string_literal: true

# This file isolates the definition of which version of Gutenberg to use.
# This way, it can be accessed by multiple sources without duplication.

# Either use commit or tag, if both are left uncommented, tag will take precedence.
#
# If you want to use a local version, please use the LOCAL_GUTENBERG environment variable when calling CocoaPods.
#
# Example:
#
#   LOCAL_GUTENBERG=../my-gutenberg-fork bundle exec pod install
GUTENBERG_CONFIG = {
  commit: '9801ec3e4acee2e0c20b9f303ea587a44f817e5c'
  # tag: 'v1.95.0'
}

GITHUB_ORG = 'wordpress-mobile'
REPO_NAME = 'gutenberg-mobile'
