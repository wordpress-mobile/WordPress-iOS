#!/usr/bin/env bash
set -euo pipefail

DEFAULT_SIMULATOR_LLM_PILOT_REF="9660424fa9aaa7e2a597b29fe2f709a615024752"

SIMULATOR_LLM_PILOT_REPO_URL="${SIMULATOR_LLM_PILOT_REPO_URL:-https://github.com/Automattic/simulator-llm-pilot.git}"
SIMULATOR_LLM_PILOT_REF="${SIMULATOR_LLM_PILOT_REF:-$DEFAULT_SIMULATOR_LLM_PILOT_REF}"
SIMULATOR_LLM_PILOT_SOURCE_PATH="${SIMULATOR_LLM_PILOT_SOURCE_PATH:-}"

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

source_path="${SIMULATOR_LLM_PILOT_SOURCE_PATH}"

if [[ -n "$source_path" ]]; then
  echo "Using local simulator-llm-pilot source at ${source_path}"
  if [[ -d "${source_path}/.git" ]]; then
    source_revision="$(git -C "${source_path}" rev-parse HEAD)"
    git -C "${source_path}" archive HEAD | tar -x -C "$build_dir"
  else
    source_revision="local-filesystem"
    tar -cf - -C "${source_path}" . | tar -xf - -C "$build_dir"
  fi
else
  echo "Fetching simulator-llm-pilot ${SIMULATOR_LLM_PILOT_REF} from ${SIMULATOR_LLM_PILOT_REPO_URL}"
  git -C "$build_dir" init --quiet
  git -C "$build_dir" remote add origin "$SIMULATOR_LLM_PILOT_REPO_URL"
  git -C "$build_dir" fetch --depth 1 origin "$SIMULATOR_LLM_PILOT_REF"
  git -C "$build_dir" checkout --quiet --detach FETCH_HEAD
  source_revision="$(git -C "$build_dir" rev-parse HEAD)"
fi

pushd "$build_dir" >/dev/null
gem build simulator-llm-pilot.gemspec >/dev/null
shopt -s nullglob
gem_files=(simulator-llm-pilot-*.gem)
shopt -u nullglob

if [[ ${#gem_files[@]} -ne 1 ]]; then
  echo "Error: expected exactly one built simulator-llm-pilot gem, found ${#gem_files[@]}" >&2
  exit 1
fi

gem install --no-document --force "./${gem_files[0]}"
popd >/dev/null

echo "Installed simulator-llm-pilot from ${source_revision}"
