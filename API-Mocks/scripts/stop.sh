#!/bin/bash

set -eu

# Use provided port, or default to 8282
PORT="${1:-8282}"

echo "Shutting down WireMock server ..."

# Shutdown the WireMock server. See http://wiremock.org/docs/running-standalone/#shutting-down
curl -X POST "http://localhost:8282/__admin/shutdown"
