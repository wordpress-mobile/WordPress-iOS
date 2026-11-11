#!/usr/bin/env bash

set -euo pipefail

example=WordPress/Credentials/Secrets-example.swift
built=DerivedData/Build/Products/Secrets/Secrets.swift

assert_example_secrets() {
  if ! cmp -s "$1" "$example"; then
    echo "GUARD: $1 is not the example secrets file"
    return 1
  fi
  echo "OK: $1 is the example secrets file"
}

echo "--- Asserting the build used example secrets"
download_artifact build-products-jetpack.tar
tar -xf build-products-jetpack.tar
[[ -f "$built" ]] || { echo "Missing $built"; exit 1; }
assert_example_secrets "$built"

echo "--- Asserting the guard catches other secrets"
tampered="$(mktemp)"
cp "$built" "$tampered"
echo "// not the example" >> "$tampered"
if output="$(assert_example_secrets "$tampered")"; then
  echo "The guard accepted a modified secrets file"
  exit 1
fi
grep -q "GUARD:" <<< "$output" || { echo "The guard failed for the wrong reason: $output"; exit 1; }
echo "OK: $output"

# The E2E script exits 0 without running when a PR lacks its label.
unset BUILDKITE_PULL_REQUEST_LABELS

exit_code=0
.buildkite/commands/run-ai-e2e-tests.sh || exit_code=$?

echo "--- Asserting the E2E tests ran"
results="$( (find Tests/AgentTests/results -name results.md 2>/dev/null || true) | head -1)"
[[ -n "$results" ]] || { echo "No results.md: the E2E tests did not run"; exit 1; }
passed="$(grep -c '^### PASS' "$results" || true)"
failed="$(grep -c '^### FAIL' "$results" || true)"
echo "E2E results: $passed passed, $failed failed"
[[ "$passed" -gt 0 ]] || { echo "No test passed"; exit 1; }

exit "$exit_code"
