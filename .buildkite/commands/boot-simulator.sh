#!/bin/bash -eu

# Starts booting a Simulator, and returns without waiting for it.
#
# A test job spends most of a minute booting its Simulator once its tests are ready to run. Started
# from the top of the job instead, the Simulator boots while the job downloads its build and
# installs its gems.
#
# DEVICE is a name, such as "iPhone 18 Pro", or a name and an iOS version, such as
# "iPhone 17 Pro (26.5)". With no version it's the newest iOS that has the device, which is the one
# fastlane picks to run the tests on.

DEVICE=${1:?Usage $0 DEVICE}

UDID=$(xcrun simctl list devices available --json | ruby -rjson -e '
  name, version = ARGV[0].match(/\A(.*?)(?: \(([\d.]+)\))?\z/).captures
  candidates = JSON.parse($stdin.read)["devices"].flat_map do |runtime, devices|
    os = runtime[/\.iOS-([\d-]+)\z/, 1]
    next [] if os.nil?

    devices.select { |device| device["name"] == name }.map { |device| [Gem::Version.new(os.tr("-", ".")), device["udid"]] }
  end
  candidates.select! { |os, _| os == Gem::Version.new(version) } unless version.nil?
  puts candidates.max_by(&:first)&.last
' "$DEVICE")

if [[ -z "$UDID" ]]; then
  echo "Found no Simulator for '$DEVICE' to boot ahead of the tests."
  exit 0
fi

echo "Booting $DEVICE ($UDID) while the job sets up"
xcrun simctl boot "$UDID" > /dev/null 2>&1 &
