#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: /bin/bash .buildkite/agent/verify.sh [--test Target/Suite[/Method] ... | --build-only | --launch | --screenshot]"
}

mode=default
test_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --test)
            [[ $# -ge 2 && ( "$mode" == default || "$mode" == test ) ]] || { usage >&2; exit 2; }
            if [[ ! "$2" =~ ^[A-Za-z_][A-Za-z0-9_.-]*/[A-Za-z_][A-Za-z0-9_.-]*(/[A-Za-z_][A-Za-z0-9_().-]*)?$ ]]; then
                echo "Tests must name an explicit Target/Suite or Target/Suite/Method." >&2
                exit 2
            fi
            mode="test"
            test_arguments+=("-only-testing:$2")
            shift 2
            ;;
        --launch|--screenshot|--build-only)
            [[ "$mode" == default ]] || { usage >&2; exit 2; }
            mode="${1#--}"
            shift
            ;;
        --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
[[ "$mode" != default ]] || mode=launch
[[ "$mode" != build-only ]] || mode=build

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
agent_setup
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
exec > >(tee "$AGENT_OUTPUT_DIR/evidence/$mode-$run_id.log") 2>&1
agent_read_simulator

if [[ "$mode" != screenshot ]]; then
    arguments=(
        -quiet
        -workspace WordPress.xcworkspace
        -scheme WordPress
        -configuration Debug
        -sdk iphonesimulator
        -destination "platform=iOS Simulator,id=$SIMULATOR_UDID"
        -derivedDataPath "$AGENT_STATE_DIR/DerivedData"
        -disableAutomaticPackageResolution
        CODE_SIGNING_ALLOWED=NO
    )
    if [[ "$mode" == test ]]; then
        xcodebuild "${arguments[@]}" -testPlan WordPressUnitTests "${test_arguments[@]}" test
    else
        xcodebuild "${arguments[@]}" build
    fi
fi

if [[ "$mode" == launch ]]; then
    xcrun simctl install "$SIMULATOR_UDID" "$AGENT_STATE_DIR/DerivedData/Build/Products/Debug-iphonesimulator/WordPress.app"
    xcrun simctl launch --terminate-running-process "$SIMULATOR_UDID" org.wordpress
    sleep 3
fi
if [[ "$mode" == launch || "$mode" == screenshot ]]; then
    xcrun simctl io "$SIMULATOR_UDID" screenshot "$AGENT_OUTPUT_DIR/evidence/simulator-$run_id.png"
fi
echo "Verification completed: $mode"
