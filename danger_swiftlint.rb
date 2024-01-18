# frozen_string_literal: true

# Dangerfile for the sole purpose of running SwiftLint and
# annotating PRs with it.

swiftlint.config_file = '.swiftlint.yml'
swiftlint.binary_path = './Pods/SwiftLint/swiftlint'
swiftlint.lint_files(inline_mode: true, fail_on_error: true)
