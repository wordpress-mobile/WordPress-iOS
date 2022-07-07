#!/bin/bash

set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
VENDOR_DIR="$(pwd)/vendor/wiremock"

WIREMOCK_VERSION="2.25.1"
WIREMOCK_JAR="${VENDOR_DIR}/wiremock-standalone-${WIREMOCK_VERSION}.jar"

if [ ! -f "$WIREMOCK_JAR" ]; then
    mkdir -p "${VENDOR_DIR}" && cd "${VENDOR_DIR}"
    curl -O -J "https://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-standalone/${WIREMOCK_VERSION}/wiremock-standalone-${WIREMOCK_VERSION}.jar"
    cd ..
fi

# Use provided port, or default to 8282
PORT="${1:-8282}"

# Start WireMock server. See http://wiremock.org/docs/running-standalone/
java -jar "${WIREMOCK_JAR}" --root-dir "${SCRIPT_DIR}/../WordPressMocks/src/main/assets/mocks" \
                            --port "$PORT" \
                            --global-response-templating
