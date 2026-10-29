#!/bin/bash
# TEMPORARY: finds why the S3 secrets hook logs "failed to parse env file" for
# this pipeline. While that parse fails, the hook doesn't redact the file's
# values from build logs.
#
# Streams the pipeline's env file from S3 into the checker in main.go, which
# prints only line numbers, variable names and line shapes, never a value.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v go > /dev/null; then
  echo "--- :golang: Installing Go"
  brew install go > /dev/null
fi

bucket="${BUILDKITE_PLUGIN_S3_SECRETS_BUCKET:-a8c-apps-ci-secrets}"
key="${BUILDKITE_PIPELINE_SLUG}/env"
echo "--- :lock: Checking s3://${bucket}/${key}"
go build -o /tmp/check-secrets-env .
aws s3 cp "s3://${bucket}/${key}" - --quiet | /tmp/check-secrets-env
