#!/bin/bash -eu

echo "--- :beer::swift: Installing swift-package-list via Homebrew"
brew tap FelixHerrmann/tap
brew trust FelixHerrmann/tap
brew install swift-package-list
