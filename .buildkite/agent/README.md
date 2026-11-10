# Iris coding task adapter

These entry points belong to WPiOS and run inside an ephemeral macOS VM as a
non-admin coding user. They are independent of the normal CI scripts, signing,
Buildkite credentials, and app secrets. The host and worker enforce the task
deadline and destroy the VM after success, failure, or cancellation.

The image must supply Xcode compatible with this checkout, Python 3, and an
installed iOS 18 or later runtime with a compatible iPhone device type. Fresh
checkouts build with plain `xcodebuild`; package downloads need network access.
This adapter does not install tools, runtimes, certificates, or credentials.
It refuses environments with `a8c-secrets` or a local
`WordPress/Credentials/Secrets.swift`, which the app's normal build phases would
otherwise use automatically. Debug builds fall back to example credentials.

The worker snapshots this adapter directory from the pinned commit and calls its
scripts with `/bin/bash` from the task checkout. The working directory selects
the repository, so edits in the checkout do not change the scripts the worker runs. It sets
two absolute paths outside the checkout:

- `AGENT_OUTPUT_DIR`: exported results; logs and screenshots go in `evidence/`.
- `AGENT_STATE_DIR`: temporary task files and DerivedData; not exported as evidence.

```bash
export AGENT_OUTPUT_DIR=/tmp/iris-task/output
export AGENT_STATE_DIR=/tmp/iris-task/state
/bin/bash .buildkite/agent/prepare.sh
/bin/bash .buildkite/agent/verify.sh
```

Preparation prefers a booted iPhone, otherwise an available iPhone on the newest
installed iOS runtime. If the user has no compatible device, it creates one from
the newest installed compatible runtime and its supported iPhone types.
Pass `--simulator-udid UUID` to select a specific existing device; a missing UUID
fails without creating a replacement.
It waits for boot and writes `$AGENT_STATE_DIR/simulator-udid`. It does not erase
or shut down other simulators. Use a disposable VM for task execution.

Verification defaults to an unsigned Debug build of the WordPress scheme using
the pinned Swift package resolutions, followed by install, launch, and a
screenshot. Use `--build-only` to omit UI verification. This is a smoke check,
not a passing test suite. Run each relevant suite explicitly and include its result
in the task's validation report:

```bash
/bin/bash .buildkite/agent/verify.sh \
  --test WordPressTest/RemoteFeatureFlagTests
```

Repeat `--test Target/Suite` to select more suites, or use
`--test Target/Suite/Method`. Tests use `WordPressUnitTests`; unrestricted test
runs and arbitrary `xcodebuild` arguments are not adapter options. See
[AGENTS.md](../../AGENTS.md) for app and testing conventions.

For UI work, build, install, and launch without signing in:

```bash
/bin/bash .buildkite/agent/verify.sh --launch
SIMULATOR_UDID="$(cat "$AGENT_STATE_DIR/simulator-udid")"
xcrun simctl ui "$SIMULATOR_UDID" appearance dark
/bin/bash .buildkite/agent/verify.sh --screenshot
```

`--launch` waits three seconds before capturing the first screen;
`--screenshot` captures the current screen
without rebuilding. Use `simctl` for launch, device settings, and screenshots.
If the image provides AXe, consult `axe --help` for accessibility inspection and
UI interaction; AXe availability and its permissions are separate image setup.
Capture screenshots after the screen has settled when documenting UI changes.

No account is needed for builds and signed-out UI. Tasks that need authentication
must stop and ask Iris for context or an approved isolated test fixture. Do not
obtain production accounts, tokens, or app secrets. The general
[simulator sign-in guide](../../docs/simulator-sign-in.md) documents launch
arguments for approved fixtures; it does not authorize credentials for a task.
Keep account data out of logs and screenshots.

Exit status is authoritative: preparation, build, test, install, launch, or
screenshot failures return nonzero. Logs persist under `evidence/` for the worker
to collect, subject to its file size limits. Preparation uses `prepare-*.log`
files separately from the worker's `prepare.log`. DerivedData stays in task state;
only source changes belong in the returned patch.

Run adapter behavior tests without Xcode or simulator access:

```bash
python3 -m unittest discover -s .buildkite/agent/tests -v
```

The tests use temporary Git checkouts, isolated home directories, and fake
`xcodebuild`/`simctl` commands. They cover preparation, log separation, build/test
arguments, failure propagation, and credential-source rejection.
