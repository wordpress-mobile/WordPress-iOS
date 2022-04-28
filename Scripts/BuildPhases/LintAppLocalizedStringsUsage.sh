#!/bin/sh

DIR="$(dirname "${BASH_SOURCE[0]}")"
swift -sdk "$(xcrun --sdk macosx --show-sdk-path)" "${DIR}/LintAppLocalizedStringsUsage.swift" "${PROJECT_FILE_PATH}" "${TARGET_NAME}"
