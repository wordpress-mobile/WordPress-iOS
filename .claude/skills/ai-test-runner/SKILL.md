---
name: ai-test-runner
description: >-
  Run a suite of plain-language markdown test cases (Prerequisites, Steps,
  Expected Outcome) against the WordPress or Jetpack iOS app via
  WebDriverAgent on an iOS Simulator. Each test case is a markdown file;
  the runner drives the app UI autonomously and reports pass/fail per test.
  Use when the user asks to run agent tests, AI tests, a UI test suite, a
  smoke run against the app, or to execute test case markdown files in a
  directory like `Tests/AgentTests/`.
---

# AI Test Runner

Run plain-language test cases against the WordPress or Jetpack iOS app. Each
test case is a markdown file with Prerequisites, Steps, and Expected Outcome.

> [!IMPORTANT]
> Use the `ios-sim-navigation` skill for all WDA lifecycle operations and app
> navigation. Its Simulator, port, session, interaction, and cleanup
> instructions are authoritative. Do not duplicate or override them here.

## Phase 1: Gather inputs

Before running tests, gather:

- **App**: WordPress or Jetpack.
- **Simulator UDID**: the exact booted Simulator supplied by the caller.
- **Test directory**: directory containing test case markdown files.
- **Site URL**: WordPress site used by the tests.
- **Sign-in credentials**: use `docs/simulator-sign-in.md`. A username plus
  application password is self-hosted; a bearer token is WordPress.com.

App bundle IDs:

- WordPress: `org.wordpress`
- Jetpack: `com.automattic.jetpack`

Resolve the absolute path to `ios-sim-navigation` and its `scripts/` directory.
Retain them as `<IOS_SIM_NAVIGATION_SKILL>` and `<WDA_SCRIPTS_DIR>`.

## Phase 2: Discover tests

1. Find all `*.md` files in the supplied directory.
2. Sort them alphabetically by filename.
3. Print the discovered files.

If no test files exist, tell the user and stop.

## Phase 3: Start WDA

Invoke `ios-sim-navigation` and follow its WDA lifecycle instructions using the
supplied Simulator UDID. Retain the selected `<PORT>` and the exact tracked
background-task identifier for the entire suite.

If WDA fails to start or become ready, stop only the retained background task,
report the failure, and stop the suite.

## Phase 4: Initialize results

Create:

```text
<base>/results/<timestamp>-<suite>/
├── <test-filename>.md
└── screenshots/
    └── <test-filename>-failure.png
```

1. Compute `<timestamp>` as `YYYY-MM-DD-HHmm`.
2. Use the test directory's last path component as `<suite>`.
3. Use the test directory's parent as `<base>`.
4. Create the run directory and screenshots directory.
5. Retain `<RESULTS_DIR>` and `<SCREENSHOTS_DIR>`.

## Phase 5: Sign in

Sign in once. Per-test app sessions preserve signed-in state. This is the only
phase that uses `-ui-test-reset-everything`.

1. Reset and terminate the app on the supplied Simulator:

   ```bash
   xcrun simctl launch --terminate-running-process \
     <UDID> <APP_BUNDLE_ID> -ui-test-reset-everything
   xcrun simctl terminate <UDID> <APP_BUNDLE_ID>
   ```

2. Follow the explicit session workflow in `ios-sim-navigation`, adding the
   credential launch arguments below to the session command:

   - Self-hosted: `--arg -ui-test-site-url --arg <SITE_URL> --arg -ui-test-site-user --arg <USERNAME> --arg -ui-test-site-pass --arg <APPLICATION_PASSWORD>`
   - WordPress.com: `--arg -ui-test-wpcom-token --arg <BEARER_TOKEN>`

   Retain the printed session ID and use it for every sign-in interaction.

3. Use `ios-sim-navigation` to wait for and drive the matching welcome flow:

   - WordPress.com: select **Continue with WordPress.com**.
   - Self-hosted: select **Enter your existing site address**, enter
     `<SITE_URL>`, and continue.

   Never type a username, application password, or bearer token into the UI.

4. Confirm a signed-in screen appears within about 20 seconds. If a web login
   form or system sign-in dialog appears, the launch credentials did not apply.
   Retry the reset, explicit session creation, and welcome flow once.

5. If the second attempt also reaches web login, stop the retained WDA
   background task and report that the credentials or canonical site URL are
   wrong.

6. Verify that the active site matches `<SITE_URL>`. Use the site switcher for
   WordPress.com when necessary.

## Phase 6: Run tests

Run tests sequentially because they share one Simulator. Track pass, fail, and
remaining counts in context.

### For each test

Derive `<test-filename>` from the markdown filename and dispatch a general
purpose subagent with this prompt:

````text
You are running one test case against an iOS app through WebDriverAgent.

## Context

- App bundle ID: <APP_BUNDLE_ID>
- Simulator UDID: <UDID>
- WDA port: <PORT>
- WDA server: already running; do not start or stop it
- ios-sim-navigation skill: <IOS_SIM_NAVIGATION_SKILL>
- WDA scripts directory: <WDA_SCRIPTS_DIR>
- Test file: <TEST_FILE_PATH>
- Results directory: <RESULTS_DIR>
- Screenshots directory: <SCREENSHOTS_DIR>
- Site URL: <SITE_URL>
- Sign-in credentials: <SIGN_IN_CREDENTIALS>

## Instructions

0. IMPORTANT: Invoke `ios-sim-navigation` before any WDA work and follow it
   exactly. WDA is already running on the supplied port, so skip only server
   start and stop. Follow its explicit app-session workflow and use its action
   commands for all UI interaction.

1. Read the test file.

2. Create a fresh app session on the supplied WDA port using the app bundle ID.
   Do not reset app data or repeat sign-in. Retain the printed session ID and
   use it for the entire test.

3. Wait for a signed-in screen. If none appears within 15 seconds, fail with
   reason `Not signed in after relaunch`.

4. Fulfill the test prerequisites. Use REST APIs for data prerequisites and
   WDA for UI prerequisites. If one cannot be fulfilled, fail with reason
   `Prerequisite not met: <details>`.

5. Execute the steps and expected outcome. Perform REST cleanup regardless of
   pass or fail.

6. Write `<RESULTS_DIR>/<test-filename>.md`.

On pass:

```text
### PASS <Test Title>
Passed.
```

On failure, capture a screenshot from the supplied UDID at
`<SCREENSHOTS_DIR>/<test-filename>-failure.png`, then write:

```text
### FAIL <Test Title>
**Failure reason:** <description>
**Screenshot:** screenshots/<test-filename>-failure.png
```

The result file is the source of truth. Its first heading must begin with
`### PASS ` or `### FAIL `.
````

After the subagent returns:

1. Read its result file.
2. Count `### PASS ` as pass and `### FAIL ` as fail.
3. Count a missing result file as failure.
4. Print `[current/total] PASS: name` or `[current/total] FAIL: name: reason`.
5. Continue to the next test after failures.

## Phase 7: Cleanup and summary

Stop the exact retained WDA background task according to
`ios-sim-navigation`. Do not stop other background tasks.

Print:

```text
Test run complete.
Total: N | Passed: P | Failed: F
Per-test results: <RESULTS_DIR>
```

If tests failed, list their filenames and result paths.

## Important notes

- The app is already built and installed on the supplied Simulator.
- Tests run sequentially.
- Each test uses a fresh explicit WDA app session but preserves app data.
- Per-test result files are the durable source of truth.
