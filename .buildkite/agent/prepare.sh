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
selection="$(python3 - "$AGENT_STATE_DIR/simulators.json" "$requested_udid" <<'PY'
import json
import re
import subprocess
import sys

with open(sys.argv[1]) as stream:
    simulators = json.load(stream)
devices = []
for runtime, entries in simulators["devices"].items():
    version = re.search(r"\.iOS-(\d+(?:-\d+)*)$", runtime)
    if not version:
        continue
    version = tuple(map(int, version[1].split("-")))
    if version[0] < 18:
        continue
    for device in entries:
        if device.get("isAvailable") and device.get("deviceTypeIdentifier", "").startswith("com.apple.CoreSimulator.SimDeviceType.iPhone-"):
            devices.append((device, version))
requested = sys.argv[2]
if requested:
    devices = [entry for entry in devices if entry[0]["udid"].lower() == requested.lower()]
    if not devices:
        raise SystemExit("The requested UUID is not an available iPhone simulator with iOS 18 or later.")
if devices:
    device, _ = max(devices, key=lambda entry: (entry[0]["state"] == "Booted", entry[1], entry[0]["name"]))
else:
    compatible = []
    for runtime in simulators["runtimes"]:
        if not runtime.get("isAvailable") or runtime.get("platform") != "iOS":
            continue
        version = tuple(map(int, runtime["version"].split(".")))
        types = [item for item in runtime["supportedDeviceTypes"] if item.get("productFamily") == "iPhone"]
        if version >= (18,) and types:
            compatible.append((version, runtime, types))
    if not compatible:
        raise SystemExit("No installed iOS 18 or later runtime with a compatible iPhone device type. Provision an iOS runtime first.")
    _, runtime, types = max(compatible, key=lambda entry: entry[0])
    device_type = min(types, key=lambda item: item["identifier"])
    udid = subprocess.check_output([
        "xcrun", "simctl", "create", "Iris task", device_type["identifier"], runtime["identifier"],
    ], text=True).strip()
    device = {"udid": udid, "state": "Shutdown"}
if not re.fullmatch(r"[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}", device["udid"]):
    raise SystemExit("simctl returned an invalid simulator UUID")
print(device["udid"], device["state"])
PY
)"
read -r simulator_udid simulator_state <<< "$selection"
if [[ "$simulator_state" != "Booted" ]]; then
    xcrun simctl boot "$simulator_udid"
fi
xcrun simctl bootstatus "$simulator_udid" -b
printf '%s\n' "$simulator_udid" > "$AGENT_STATE_DIR/simulator-udid.tmp"
mv "$AGENT_STATE_DIR/simulator-udid.tmp" "$AGENT_STATE_DIR/simulator-udid"
echo "Simulator ready: $simulator_udid"
