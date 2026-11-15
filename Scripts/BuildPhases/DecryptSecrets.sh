#!/usr/bin/env bash

set -euo pipefail

# Runs from the `Decrypt Secrets` aggregate target so it happens once per build:
# `a8c-secrets decrypt` is not safe to run concurrently, and the ten targets that
# consume the secrets build in parallel.

# Build phases don't inherit the shell's PATH, so point at a8c-secrets' default
# install location.
export PATH="$HOME/.local/bin:$PATH"

# External contributors build with their own credentials and never install the tool.
if ! command -v a8c-secrets > /dev/null 2>&1; then
  echo "warning: a8c-secrets not installed; skipping secrets decryption."
  exit 0
fi

a8c-secrets decrypt --non-interactive
