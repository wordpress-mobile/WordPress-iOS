#!/bin/bash

set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
VENDOR_DIR="$(pwd)/vendor/wiremock"
BUILD_ARTIFACTS_DIR="$(pwd)/build/logs"

WIREMOCK_VERSION="2.35.2"
WIREMOCK_JAR="${VENDOR_DIR}/wiremock-jre8-standalone-${WIREMOCK_VERSION}.jar"

if [ ! -f "$WIREMOCK_JAR" ]; then
    mkdir -p "${VENDOR_DIR}" && cd "${VENDOR_DIR}"
    curl -O -J "https://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-jre8-standalone/${WIREMOCK_VERSION}/wiremock-jre8-standalone-${WIREMOCK_VERSION}.jar"
    cd ..
fi

# Use provided port, or default to 8282
PORT="${1:-8282}"

# Start WireMock server. See http://wiremock.org/docs/running-standalone/
# Redirect output to a log file on CI to reduce log noise
OUTPUT_REDIRECT="/dev/stdout"
if [ -n "${BUILDKITE:-}" ]; then
    OUTPUT_REDIRECT="${BUILD_ARTIFACTS_DIR}/wiremock.txt"
    mkdir -p "$BUILD_ARTIFACTS_DIR"
fi
java -jar "${WIREMOCK_JAR}" --root-dir "${SCRIPT_DIR}/../WordPressMocks/src/main/assets/mocks" \
                            --port "$PORT" \
                            --global-response-templating > "$OUTPUT_REDIRECT" 2>&1
