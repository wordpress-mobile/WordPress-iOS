#!/usr/bin/env bash

# The `Generate Credentials` build phase resolves `a8c-secrets` off PATH, so the
# export below has to survive in the caller's shell.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be sourced, not executed, because it exports PATH." >&2
  exit 1
fi

set -euo pipefail

# `install_a8c-secrets_binary` comes from the a8c-ci-toolkit plugin. It pins the
# a8c-secrets version and checks the download against a checksum vendored there.
install_dir="$HOME/.local/bin"
install_a8c-secrets_binary --install-dir "$install_dir"
export PATH="$install_dir:$PATH"

echo "--- :closed_lock_with_key: Installing Secrets"
a8c-secrets decrypt
