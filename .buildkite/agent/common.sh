#!/bin/bash

agent_setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    export REPO_ROOT
    : "${AGENT_OUTPUT_DIR:?Set AGENT_OUTPUT_DIR to an absolute output directory}"
    : "${AGENT_STATE_DIR:?Set AGENT_STATE_DIR to an absolute task state directory}"
    ruby --disable=rubyopt - <<'RUBY_CHECK'
require 'pathname'

root = Pathname.new(ENV.fetch('REPO_ROOT')).realpath
%w[AGENT_OUTPUT_DIR AGENT_STATE_DIR].each do |name|
  path = Pathname.new(ENV.fetch(name))
  abort "#{name} must be an absolute directory outside the checkout" unless path.absolute?

  # Resolve one component at a time so symlinks before '..' keep their meaning.
  resolved = path.each_filename.reduce(Pathname.new('/')) do |parent, component|
    candidate = parent.join(component).cleanpath
    candidate.symlink? ? candidate.realpath : candidate
  end
  if resolved.ascend.any? { |entry| entry.exist? && File.identical?(entry, root) }
    abort "#{name} must be an absolute directory outside the checkout"
  end
end
RUBY_CHECK

    umask 077
    mkdir -p "$AGENT_OUTPUT_DIR/evidence" "$AGENT_STATE_DIR"
    cd "$REPO_ROOT" || return
    if command -v a8c-secrets >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/a8c-secrets" || -e WordPress/Credentials/Secrets.swift ]]; then
        echo "Use a clean coding environment without a8c-secrets or WordPress/Credentials/Secrets.swift." >&2
        return 1
    fi
}

agent_read_simulator() {
    if [[ ! -f "$AGENT_STATE_DIR/simulator-udid" ]]; then
        echo "Run .buildkite/agent/prepare.sh before verification." >&2
        return 1
    fi
    SIMULATOR_UDID="$(cat "$AGENT_STATE_DIR/simulator-udid")"
    if [[ ! "$SIMULATOR_UDID" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
        echo "Invalid simulator UUID in task state." >&2
        return 1
    fi
}
