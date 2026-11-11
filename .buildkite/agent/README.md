# WPiOS setup for remote coding tasks

These scripts give a coding agent a way to build WPiOS and see its changes in
a simulator. They run in a disposable Mac VM as a non-admin user, with the
worker taking care of the task deadline and the host cleaning up afterward.

The image needs a compatible Xcode, Python 3, and an installed iOS 18 or later
runtime with an iPhone device type. Package downloads need network access.
Builds use example credentials for signed-out UI; the scripts refuse environments
with `a8c-secrets` or `WordPress/Credentials/Secrets.swift` so the normal build
phases won't pick up production secrets.

## Build and run

The worker sets two absolute paths outside the checkout: `AGENT_OUTPUT_DIR`
for results and `AGENT_STATE_DIR` for temporary files and DerivedData. To try
the scripts in a clean VM:

```bash
export AGENT_OUTPUT_DIR=/tmp/iris-task/output
export AGENT_STATE_DIR=/tmp/iris-task/state
/bin/bash .buildkite/agent/prepare.sh
/bin/bash .buildkite/agent/verify.sh
```

Preparation reuses a booted iPhone where possible, otherwise choosing one on
the newest installed runtime. If there isn't a compatible device, it creates
one. You can select an existing device with `--simulator-udid UUID`; an invalid
or missing UUID fails rather than silently choosing something else. Once the
device has booted, its UUID is saved in `$AGENT_STATE_DIR/simulator-udid`.
Other simulators are left alone.

Verification builds the WordPress scheme as an unsigned Debug app using the
pinned Swift package resolutions, then installs it, launches it and takes a
screenshot. Use `--build-only` if you only need a build. This default check
shows that the app builds and opens; run the relevant tests separately:

```bash
/bin/bash .buildkite/agent/verify.sh \
  --test WordPressTest/RemoteFeatureFlagTests
```

Tests use the `WordPressUnitTests` plan. Repeat `--test Target/Suite` for more
suites, or use `--test Target/Suite/Method` for one test. The adapter requires
explicit selectors and doesn't accept arbitrary `xcodebuild` arguments. Follow
[AGENTS.md](../../AGENTS.md) for the app's testing conventions and include the
checks you ran in the task report.

## Looking at UI changes

For example, to launch the app and capture it in dark mode:

```bash
/bin/bash .buildkite/agent/verify.sh --launch
SIMULATOR_UDID="$(cat "$AGENT_STATE_DIR/simulator-udid")"
xcrun simctl ui "$SIMULATOR_UDID" appearance dark
/bin/bash .buildkite/agent/verify.sh --screenshot
```

`--launch` waits three seconds before its first screenshot. `--screenshot`
captures the current screen without rebuilding, so you can wait for a screen
to settle or navigate to the part you changed. Use `simctl` for device settings
and screenshots, and `axe --help` for UI interaction if AXe and its permissions
are set up in the image.

Signed-out UI doesn't need an account. If a task needs authentication, stop and
ask Iris for an approved test fixture instead of finding production credentials.
The [simulator sign-in guide](../../docs/simulator-sign-in.md) explains the launch
arguments for an approved fixture. Keep account data out of logs and screenshots.

## Draft PRs and CI

When a task has a change that passes its checks, the pilot opens a draft PR for
us to review. This happens after its VM has been removed, so the coding agent
does not need GitHub credentials. These PRs use `iris/task-<task_id>` branches.
Automatic Buildkite builds, Danger
event retries, and `@claude` reviews stay off for them, even after marking a draft
ready for review.

Once a maintainer has reviewed the diff, they can run this from buildkite-ci:

```sh
python3 src/scripts/run-iris-pr-ci.py \
  https://github.com/wordpress-mobile/WordPress-iOS/pull/123 \
  --commit <full-reviewed-sha>
```

The command uses the maintainer's GitHub CLI login and `BUILDKITE_API_TOKEN`.
It checks that the PR still points to the reviewed commit and starts normal
WPiOS CI with the PR metadata. Add `--dry-run` to inspect the request first.
This gives the reviewed code normal CI access, so review comes before running
the command. Keep the original branch name so the PR stays open.

Publication stays disabled until the Buildkite branch filter and GitHub workflow
guards are deployed. Tasks must start from a commit on trunk. The publisher pins
an approved guard baseline and rejects changes to `.github/`, `.buildkite/`,
and `.gitmodules`.

## What the worker collects

Logs and screenshots go under `$AGENT_OUTPUT_DIR/evidence`. Preparation uses
`prepare-*.log` so it doesn't overwrite the worker's own log. DerivedData stays
in task state, outside the source patch. Any failed prepare, build, test,
install, launch or screenshot command returns a nonzero exit status.

The worker copies this adapter from the requested commit before editing starts
and runs the copy through `/bin/bash`, with the checkout as its working
directory. Editing the checkout's scripts won't change that final check.

To check the adapter itself without Xcode or a simulator:

```bash
python3 -m unittest discover -s .buildkite/agent/tests -v
```

These tests use temporary checkouts and substitute `xcodebuild` and `simctl`
commands to cover setup, command arguments, logs and failures.
