#!/bin/bash -eu

if "$(dirname "${BASH_SOURCE[0]}")/should-skip-job.sh" --job-type localization; then
  exit 0
fi

lint_localized_strings_format
