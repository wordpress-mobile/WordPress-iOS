#!/bin/bash -eu

echo "--- :beer::swift: Installing swift-package-list via Homebrew"
brew tap FelixHerrmann/tap
if brew help trust >/dev/null 2>&1; then
  brew trust FelixHerrmann/tap
fi
brew install swift-package-list
