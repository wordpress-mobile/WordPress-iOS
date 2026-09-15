#!/bin/bash -eu

# Homebrew 6 ask-mode prompts before installing dependencies and hangs on the CI PTY.
export HOMEBREW_NO_ASK=1

echo "--- :beer: Installing Homebrew Dependencies"
"$(dirname "${BASH_SOURCE[0]}")/install-swift-package-list.sh"

brew install imagemagick
brew install ghostscript
