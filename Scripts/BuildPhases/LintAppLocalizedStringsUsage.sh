#!/bin/bash -eu

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
SCRIPT_SRC="${SCRIPT_DIR}/LintAppLocalizedStringsUsage.swift"

LINTER_BUILD_DIR="${BUILD_DIR:-${TMPDIR}}"
LINTER_EXEC="${LINTER_BUILD_DIR}/$(basename "${SCRIPT_SRC}" .swift)"

if [ ! -x "${LINTER_EXEC}" ] || ! (shasum -c "${LINTER_EXEC}.shasum" >/dev/null 2>/dev/null); then
  echo "Pre-compiling linter script to ${LINTER_EXEC}..."
  swiftc -O -sdk "$(xcrun --sdk macosx --show-sdk-path)" "${SCRIPT_SRC}" -o "${LINTER_EXEC}"
  shasum "${SCRIPT_SRC}" >"${LINTER_EXEC}.shasum"
  chmod +x "${LINTER_EXEC}"
  echo "Pre-compiled linter script ready"
fi

if [ -z "${PROJECT_FILE_PATH:=${1:-}}" ]; then
  echo "error: Please provide the path to the xcodeproj to scan"
  exit 1
fi
"$LINTER_EXEC" "${PROJECT_FILE_PATH}" "${@:2}"
