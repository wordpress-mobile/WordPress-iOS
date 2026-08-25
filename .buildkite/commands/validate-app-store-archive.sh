#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")/.."
IPA="${REPO_ROOT}/Artifacts/WordPress.ipa"

"${SCRIPT_DIR}/shared-set-up.sh"
"${SCRIPT_DIR}/shared-set-up-distribution.sh"
"${SCRIPT_DIR}/install-secrets.sh"

echo "--- :hammer_and_wrench: Building App Store archive (stop before ASC upload)"
LOG="$(mktemp)"
bundle exec fastlane build_and_upload_app_store_connect skip_confirm:true | tee "${LOG}"

if ! grep -F 'VALIDATION: archive succeeded' "${LOG}"; then
  echo "VALIDATION: lane did not print the archive-succeeded marker; refusing to treat this as a pass"
  exit 1
fi

if [[ ! -f "${IPA}" ]]; then
  echo "VALIDATION: expected IPA at ${IPA}"
  exit 1
fi

SIZE="$(stat -f%z "${IPA}")"
if (( SIZE == 0 )); then
  echo "VALIDATION: IPA at ${IPA} is empty"
  exit 1
fi

echo "VALIDATION: archive succeeded (${SIZE} bytes at ${IPA}); ASC upload was not invoked"
