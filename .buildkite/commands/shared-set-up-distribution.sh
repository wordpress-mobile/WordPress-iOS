#!/bin/bash -eu

echo "--- :beer: Installing Homebrew Dependencies"
# Sentry CLI needs to be up-to-date
brew upgrade sentry-cli

"$(dirname "${BASH_SOURCE[0]}")/install-swift-package-list.sh"

brew install imagemagick
brew install ghostscript
