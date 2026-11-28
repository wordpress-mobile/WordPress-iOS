#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: /bin/bash .buildkite/agent/prepare.sh [--simulator-udid UUID]"
}

requested_udid=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --simulator-udid)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            [[ "$2" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || { usage >&2; exit 2; }
            requested_udid="$2"
            shift 2
            ;;
        --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
agent_setup
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
exec > >(tee "$AGENT_OUTPUT_DIR/evidence/prepare-$run_id.log") 2>&1

rm -f "$AGENT_STATE_DIR/simulator-udid"
xcodebuild -version
xcrun simctl list --json > "$AGENT_STATE_DIR/simulators.json"
selection="$(ruby --disable=rubyopt - "$AGENT_STATE_DIR/simulators.json" "$requested_udid" <<'RUBY_SELECT'
require 'json'
require 'open3'

simulators = JSON.parse(File.read(ARGV.fetch(0)))
devices = simulators.fetch('devices').flat_map do |runtime, entries|
  match = /\.iOS-(\d+(?:-\d+)*)\z/.match(runtime)
  next [] unless match

  version = match[1].split('-').map(&:to_i)
  next [] if version.first < 18

  entries.filter_map do |device|
    next unless device['isAvailable'] && device.fetch('deviceTypeIdentifier', '').start_with?('com.apple.CoreSimulator.SimDeviceType.iPhone-')

    [device, version]
  end
end
requested = ARGV.fetch(1)
unless requested.empty?
  devices.select! { |device, _version| device.fetch('udid').casecmp?(requested) }
  abort 'The requested UUID is not an available iPhone simulator with iOS 18 or later.' if devices.empty?
end
if devices.empty?
  compatible = simulators.fetch('runtimes').filter_map do |runtime|
    next unless runtime['isAvailable'] && runtime['platform'] == 'iOS'

    version = runtime.fetch('version').split('.').map(&:to_i)
    types = runtime.fetch('supportedDeviceTypes').select { |type| type['productFamily'] == 'iPhone' }
    [version, runtime, types] if version.first >= 18 && !types.empty?
  end
  abort 'No installed iOS 18 or later runtime with a compatible iPhone device type. Provision an iOS runtime first.' if compatible.empty?

  _version, runtime, types = compatible.max_by(&:first)
  device_type = types.min_by { |type| type.fetch('identifier') }
  udid, status = Open3.capture2('xcrun', 'simctl', 'create', 'Iris task', device_type.fetch('identifier'), runtime.fetch('identifier'))
  abort 'Could not create an iPhone simulator.' unless status.success?

  device = { 'udid' => udid.strip, 'state' => 'Shutdown' }
else
  device, = devices.max_by { |entry, version| [entry['state'] == 'Booted' ? 1 : 0, version, entry.fetch('name')] }
end
abort 'simctl returned an invalid simulator UUID' unless /\A[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}\z/.match?(device.fetch('udid'))

puts "#{device.fetch('udid')} #{device.fetch('state')}"
RUBY_SELECT
)"
read -r simulator_udid simulator_state <<< "$selection"
if [[ "$simulator_state" != "Booted" ]]; then
    xcrun simctl boot "$simulator_udid"
fi
xcrun simctl bootstatus "$simulator_udid" -b
printf '%s\n' "$simulator_udid" > "$AGENT_STATE_DIR/simulator-udid.tmp"
mv "$AGENT_STATE_DIR/simulator-udid.tmp" "$AGENT_STATE_DIR/simulator-udid"
echo "Simulator ready: $simulator_udid"
