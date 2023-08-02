#!/bin/bash -eu

# Close all Simulators so they'll use the settings we'll configure below when relaunched
xcrun simctl shutdown all

# Disable the hardware keyboard in the Simulator
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
