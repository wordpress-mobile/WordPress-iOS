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

Run plain-language test cases against the WordPress or Jetpack iOS app on an
iOS Simulator. Each test case is a markdown file with Prerequisites, Steps,
and Expected Outcome. Claude Code navigates the app UI autonomously using
WebDriverAgent.

## Phase 1: Gather Inputs

Before running any tests, ask the user for:

- **App**: WordPress or Jetpack
- **Test directory**: directory containing test case markdown files
- **Site URL**: the WordPress site to test against (used for REST API
  calls and for picking the right site in the app)
- **Sign-in credentials**: see `docs/simulator-sign-in.md` for the two
  supported flows. Infer the flow from what the user provides — a username
  with application password is the self-hosted flow; a WordPress.com
  bearer token is the WordPress.com flow.

App bundle IDs:
- **WordPress**: `org.wordpress`
- **Jetpack**: `com.automattic.jetpack`

Also resolve the absolute path to the `ios-sim-navigation` skill's
`scripts/` directory and store it as `<WDA_SCRIPTS_DIR>` for use in
Phases 3, 5, 6, and 7 — typically
`<project-root>/.claude/skills/ios-sim-navigation/scripts` on this
project.

## Phase 2: Discover Tests

1. Use Glob to find all `*.md` files in the directory the user specified.
2. Sort them alphabetically by filename.
3. Print the list of discovered tests to the terminal:
   ```
   Discovered N test(s) in <dir>:
   - view-media-library.md
   - view-posts-list.md
   - view-site-settings.md
   ```

If no `.md` files are found, tell the user and stop.

## Phase 3: Start WDA

1. Run `<WDA_SCRIPTS_DIR>/wda-start.rb` from the project root that
   should own `.build/WebDriverAgent`. First run takes a couple of
   minutes; warm runs ~60 s.

2. Confirm WDA is responding:
   ```bash
   curl -sf http://localhost:8100/status >/dev/null
   ```

3. Get the booted simulator UDID for screenshots and per-test relaunches:
   ```bash
   xcrun simctl list devices booted -j | jq -r '.devices | to_entries[].value[] | select(.state == "Booted") | .udid'
   ```

If WDA fails to start, doesn't respond, or no simulator is booted, run
`<WDA_SCRIPTS_DIR>/wda-stop.rb` to clean up any stray `xcodebuild`
process, tell the user, and stop.

## Phase 4: Initialize Results Directory

```
<base>/results/<timestamp>-<suite>/
├── <test-filename>.md                  # per-test files (Phase 6)
└── screenshots/
    └── <test-filename>-failure.png     # failures only (Phase 6)
```

1. Compute the timestamp as `YYYY-MM-DD-HHmm` from the current date and time.
2. Determine the suite name from the test directory's last path component (e.g., `ui-tests`).
3. Derive the base directory as the **parent** of the test directory (e.g., if the test
   directory is `ai-tests/ui-tests`, the base directory is `ai-tests/`).
4. Create the run directory and its screenshots subdirectory in one
   call: `mkdir -p <base>/results/<timestamp>-<suite>/screenshots`.
5. Store these paths in context for use in later phases:
   - `<RESULTS_DIR>` = `<base>/results/<timestamp>-<suite>`
   - `<SCREENSHOTS_DIR>` = `<RESULTS_DIR>/screenshots`

## Phase 5: Sign In

Sign in once. Test relaunches in Phase 6 preserve the signed-in state, so each
test skips sign-in. This is the only phase that uses `-ui-test-reset-everything`.
If any step below fails, run `<WDA_SCRIPTS_DIR>/wda-stop.rb` to release the
simulator, tell the user, and stop.

The credentials are launch arguments, and `wda-session.rb` is what gets them
into the app: it launches the app with the arguments and binds the WDA session
in one step, so the process you drive actually has the credentials. Don't
relaunch the app any other way before it's signed in, or the arguments are lost
and the app drops into a web login that launch arguments can't complete.

1. **Reset to a clean, signed-out state** (kept separate from the credentialed
   launch, since reset clears `UserDefaults`):

   ```bash
   xcrun simctl launch --terminate-running-process <UDID> <APP_BUNDLE_ID> -ui-test-reset-everything
   xcrun simctl terminate <UDID> <APP_BUNDLE_ID>
   ```

2. **Create the credentialed WDA session**, passing each launch-argument token
   as an `--arg`:

   - Self-hosted: `--arg -ui-test-site-url --arg <SITE_URL> --arg -ui-test-site-user --arg <username> --arg -ui-test-site-pass --arg <application-password>`
   - WordPress.com: `--arg -ui-test-wpcom-token --arg <bearer-token>`

   ```bash
   ruby <WDA_SCRIPTS_DIR>/wda-session.rb --bundle <APP_BUNDLE_ID> --arg ... --arg ...
   ```

   Then poll the accessibility tree (`GET /source`, no session needed) until the
   welcome screen appears.

3. **Tap through the welcome screen** for the matching flow:

   - WordPress.com: tap **"Continue with WordPress.com"**.
   - Self-hosted: tap **"Enter your existing site address"**, type `<SITE_URL>`,
     tap **"Continue"**.

   Never type a username, password, or bearer token — the launch arguments
   supply those.

4. **Confirm sign-in, and fail fast if it didn't take.** Poll for a signed-in
   screen (e.g. My Site) for up to ~20 s. If instead a web login form or a
   system dialog "<App> Wants to Use <site> to Sign In" appears (the dialog
   won't show in `GET /source`; check `GET /session/<sid>/alert/text`), the
   credentials didn't apply. Don't type into the web form or wait on the
   spinner. Retry once with WDA left running: reset (step 1), recreate the
   session (step 2), tap through (step 3). If it still hits the web flow, the
   credentials or `<SITE_URL>` are wrong (often a scheme/host mismatch with the
   site's canonical URL) — run `wda-stop.rb`, tell the user, and stop.

5. **Verify the active site matches `<SITE_URL>`.** For self-hosted this is
   automatic. For WordPress.com, use the site switcher if a different site is
   currently selected.

## Phase 6: Run Tests

Run each test case **sequentially**. Tests share one simulator so they must not
run in parallel.

Track pass/fail/remaining counts in-context (incrementing counters).

### For each test case:

#### Step 1: Dispatch subagent

Derive `<test-filename>` as the test file's basename without the `.md`
extension (e.g. `create-blank-page.md` → `create-blank-page`). Store
it for use here and in Step 2.

Call the Agent tool with `subagent_type: general-purpose`, `model: "sonnet"`,
and a prompt constructed from the template below.

Build the prompt by filling in the `<PLACEHOLDERS>` with actual values:

````
You are running a single test case against an iOS app in a simulator
using WebDriverAgent (WDA). The app under test is `<APP_BUNDLE_ID>`.

## Context

- App Bundle ID: <APP_BUNDLE_ID>
- Simulator UDID: <UDID>
- WDA: already running on http://localhost:8100 (do not start or stop it)
- Test file: <TEST_FILE_PATH> (absolute path)
- Results directory: <RESULTS_DIR> (absolute path; write your per-test
  result file here as `<test-filename>.md`)
- Screenshots directory: <SCREENSHOTS_DIR> (absolute; sibling
  `screenshots/` of the per-test result file)
- Site URL: <SITE_URL>
- Sign-in credentials: <SIGN_IN_CREDENTIALS> (self-hosted: username +
  application password; WordPress.com: bearer token; see
  `docs/simulator-sign-in.md`)
- WDA scripts directory: <WDA_SCRIPTS_DIR> (absolute path; contains
  `tap.rb`, `wda-start.rb`, `wda-stop.rb`)

## Instructions

0. **Load WDA guidance.** Invoke the `ios-sim-navigation` skill via the
   Skill tool before any WDA work. Rewrite any `scripts/tap.rb`
   reference in that skill as `<WDA_SCRIPTS_DIR>/tap.rb`.

1. **Read the test file** at `<TEST_FILE_PATH>`. It contains the
   information needed to execute the test: prerequisites, steps,
   expected outcome, etc.

2. **Relaunch the app** for a clean per-test UI state. The app is
   already signed in — do not pass `-ui-test-reset-everything` and do
   not re-drive the sign-in flow.

   ```bash
   xcrun simctl launch --terminate-running-process <UDID> <APP_BUNDLE_ID>
   ```

   Poll the accessibility tree until a signed-in screen (e.g. My Site)
   appears. If it doesn't appear within 15 s, mark the test as FAIL
   with reason "Not signed in after relaunch".

3. **Fulfill prerequisites** from the test file.

   For REST API prerequisites (e.g., creating tags, categories, or posts),
   make the API calls using the credentials in `<SIGN_IN_CREDENTIALS>`.
   For UI prerequisites like "Logged in to the app with the test account",
   the app relaunch in step 2 handles this automatically.

   If a prerequisite cannot be fulfilled, mark the test as FAIL with
   reason "Prerequisite not met: <details>".

4. **Execute the test case** following the steps, expected outcome, and any
   verification/cleanup sections in the test file. Use WDA for all UI
   interactions (refer to the ios-sim-navigation skill). Perform any REST API
   cleanup regardless of pass/fail.

5. **Write per-test result file** at
   `<RESULTS_DIR>/<test-filename>.md`:

   On pass — write:
   ```
   ### PASS <Test Title>
   Passed.
   ```

   On fail — take a failure screenshot, save it, then write:
   ```bash
   xcrun simctl io <UDID> screenshot <SCREENSHOTS_DIR>/<test-filename>-failure.png
   ```
   ```
   ### FAIL <Test Title>
   **Failure reason:** <description of what went wrong>
   **Screenshot:** screenshots/<test-filename>-failure.png
   ```

The per-test result file is the source of truth for pass/fail. The parent
orchestrator reads it after this subagent returns, so the heading line
(`### PASS <title>` or `### FAIL <title>`) must be written correctly.
````

#### Step 2: Read the per-test result file

After the subagent returns, read `<RESULTS_DIR>/<test-filename>.md`:

- A line starting with `### PASS ` means pass.
- A line starting with `### FAIL ` means fail; the failure reason is on
  the `**Failure reason:**` line beneath it.
- If the file is missing, count the test as fail with reason "Subagent
  did not produce a result file".

Update the in-context counters accordingly.

#### Step 3: Print status update

```
[2/5] PASS: create-blank-page
```
or:
```
[2/5] FAIL: create-blank-page — <reason>
```

## Phase 7: Cleanup and Summary

1. Stop WDA by running `<WDA_SCRIPTS_DIR>/wda-stop.rb`.

2. Print the final summary to the terminal:
   ```
   Test run complete.
   Total: N | Passed: P | Failed: F
   Per-test results: <RESULTS_DIR>
   ```
   If any tests failed, list the failing filenames under the summary so
   the user can jump straight to the relevant per-test files and
   screenshots.

## Important Notes

- Assumes the app is already built and installed on a booted simulator.
- Continue to the next test even on failure. The suite reports the full
  pass/fail tally at the end, so a single failure should not stop the run.
- Each test case runs in its own subagent to keep the main context lean.
  Per-test result files in `<RESULTS_DIR>` are the durable record of the
  run.
