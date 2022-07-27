#!/bin/zsh

# This is a revised version of the ZSH completion script for fastlane
# which adds support for some lanes being defined in `fastlane/lanes/*.rb`
#
# Based on https://github.com/fastlane/fastlane/blob/master/fastlane/lib/assets/completions/completion.zsh
#
# To install, copy this file to `~/.fastlane/completions/completion.zsh`,
# then `source` it from your `~/.zshrc`.
#
_fastlane_complete() {
  local word completions file
  word="$1"

  # look for Fastfile either in this directory or fastlane/ then grab the lane names
  if [[ -e "Fastfile" ]] then
    file=("Fastfile")
  elif [[ -e "fastlane/Fastfile" ]] then
    file=("fastlane/Fastfile")
  elif [[ -e ".fastlane/Fastfile" ]] then
    file=(".fastlane/Fastfile")
  else
    return 1
  fi

  # Add any fastlane/lanes/*.rb file too, if any
  files=("$file" fastlane/lanes/*.rb(N))

  # parse 'beta' out of 'lane :beta do', etc
  completions="$(sed -En 's/^[ 	]*lane +:([^ 	]+).*$/\1/p' "${files[@]}")"
  completions="$completions update_fastlane"

  reply=( "${=completions}" )
}

compctl -K _fastlane_complete bundle exec fastlane
