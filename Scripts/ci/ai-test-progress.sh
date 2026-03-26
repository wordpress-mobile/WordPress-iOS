#!/usr/bin/env bash

log_ai_test_progress() {
  local message="${1:-}"

  if [[ -z "$message" || -z "${AI_TEST_PROGRESS_FILE:-}" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$AI_TEST_PROGRESS_FILE")"
  printf '[%s] %s\n' "$(date +%H:%M:%S)" "$message" >> "$AI_TEST_PROGRESS_FILE"
}
