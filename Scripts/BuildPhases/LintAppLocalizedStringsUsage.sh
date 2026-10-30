#!/bin/bash -eu

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
SCRIPT_SRC="${SCRIPT_DIR}/LintAppLocalizedStringsUsage.swift"

LINTER_BUILD_DIR="${BUILD_DIR:-${TMPDIR}}"
LINTER_EXEC="${LINTER_BUILD_DIR}/$(basename "${SCRIPT_SRC}" .swift)"

if [ ! -x "${LINTER_EXEC}" ] || ! (shasum -c "${LINTER_EXEC}.shasum" >/dev/null 2>/dev/null); then
  echo "Pre-compiling linter script to ${LINTER_EXEC}..."
  MACOSX_SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
  # The build exports a simulator `SDKROOT`, which `swiftc` would otherwise pick up and warn about
  # while compiling this macOS tool.
  SDKROOT="${MACOSX_SDK_PATH}" swiftc -O -sdk "${MACOSX_SDK_PATH}" "${SCRIPT_SRC}" -o "${LINTER_EXEC}"
  shasum "${SCRIPT_SRC}" >"${LINTER_EXEC}.shasum"
  chmod +x "${LINTER_EXEC}"
  echo "Pre-compiled linter script ready"
fi

if [ -z "${PROJECT_FILE_PATH:=${1:-}}" ]; then
  echo "error: Please provide the path to the xcodeproj to scan"
  exit 1
fi
"$LINTER_EXEC" "${PROJECT_FILE_PATH}" "${@:2}"
