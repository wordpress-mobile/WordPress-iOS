---
name: ai-test-runner
description: >-
  Run a suite of AI-driven test cases against the WordPress and Jetpack iOS
  app in a simulator. Use when asked to run a test suite, run AI tests, or
  execute test cases in a directory.
---

# AI Test Runner

Run plain-language test cases against the WordPress or Jetpack iOS app on an
iOS Simulator. Each test case is a markdown file with Prerequisites, Steps,
and Expected Outcome. Claude Code navigates the app UI autonomously using
WebDriverAgent.

## Phase 1: Collect Credentials

Before running any tests, ask the user for the following using AskUserQuestion.

- **App**: Which app to test — WordPress or Jetpack
- **Site URL**: The WordPress site URL (e.g., `https://example.com`)
- **Username**: The WordPress username or email
- **Application Password**: A WordPress application password for REST API access
- **Test directory**: Path to the directory containing test case markdown files

Here are the app bundle IDs:
- **WordPress**: `org.wordpress`
- **Jetpack**: `com.automattic.jetpack`

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

1. Run the WDA start script, which locates at `scripts/wda-start.rb` in the
   `ios-sim-navigation` skill directory. This may take up to 60 seconds the first time.

2. Create a WDA session:
   ```bash
   curl -s -X POST http://localhost:8100/session \
     -H 'Content-Type: application/json' \
     -d '{"capabilities":{"alwaysMatch":{}}}'
   ```
   Extract the session ID from `value.sessionId` in the response.

3. Get the booted simulator UDID for screenshots:
   ```bash
   xcrun simctl list devices booted -j | jq -r '.devices | to_entries[].value[] | select(.state == "Booted") | .udid'
   ```

If WDA fails to start or no simulator is booted, tell the user and stop.

## Phase 4: Initialize Results Directory

1. Compute the timestamp as `YYYY-MM-DD-HHmm` from the current date and time.
2. Determine the suite name from the test directory's last path component (e.g., `ui-tests`).
3. Derive the base directory as the **parent** of the test directory (e.g., if the test
   directory is `ai-tests/ui-tests`, the base directory is `ai-tests/`).
4. Create the per-test results directory: `mkdir -p <base>/results/<timestamp>-<suite>`
5. Create the screenshots directory: `mkdir -p <base>/results/screenshots`
6. Store the results directory path, screenshots directory path, timestamp, and suite name
   in context for use in later phases.

## Phase 5: Run Tests

Run each test case **sequentially**. Tests share one simulator so they must not
run in parallel.

Track pass/fail/remaining counts in-context (incrementing counters).

### For each test case:

#### Step 1: Dispatch subagent

Call the Agent tool with `subagent_type: general-purpose` and a prompt
constructed from the template below.

Build the prompt by filling in the `<PLACEHOLDERS>` with actual values:

````
You are running a single test case against the <APP_NAME> iOS app in a simulator
using WebDriverAgent (WDA).

Use the ios-sim-navigation skill for WDA interaction reference.

## Context

- App Bundle ID: <APP_BUNDLE_ID>
- WDA Session ID: <SESSION_ID>
- Simulator UDID: <UDID>
- Test file: <TEST_FILE_PATH> (absolute path)
- Per-test results directory: <PER_TEST_RESULTS_DIR> (absolute path)
- Site URL: <SITE_URL>
- Username: <USERNAME>
- Application Password: <APPLICATION_PASSWORD>
- Screenshots directory: <SCREENSHOTS_DIR> (absolute path)

## Instructions

1. **Read the test file** at `<TEST_FILE_PATH>`. It contains the information
   needed to execute the test: prerequisites, steps, expected outcome, etc.

   Derive the test filename (without extension) from the file path for use
   in result files and screenshots.

2. **Relaunch the app** for a clean state:

   ```bash
   xcrun simctl launch --terminate-running-process <UDID> <APP_BUNDLE_ID> \
     -ui-test-site-url <SITE_URL> \
     -ui-test-site-user <USERNAME> \
     -ui-test-site-pass <APPLICATION_PASSWORD>
   ```

   Wait 2-3 seconds for the app to finish loading.

   The app may already be logged in to the site. Check the accessibility tree
   to determine if login is required. If the app is already showing the
   logged-in state (e.g., My Site screen), skip login.

   If the app shows a login/signup screen, log in using these steps:

   1. Tap the **"Enter your existing site address"** button.
   2. Type the exact site URL value into the site address text field.
   3. Tap **Continue**. The app will auto-login after this.

   Wait 2-3 seconds for the app to finish loading after login.

3. **Fulfill prerequisites** from the test file.

   For REST API prerequisites (e.g., creating tags, categories, or posts),
   make the API calls using the site URL, username, and application password.
   For UI prerequisites like "Logged in to the app with the test account",
   the app relaunch in step 2 handles this automatically.

   If a prerequisite cannot be fulfilled, mark the test as FAIL with reason
   "Prerequisite not met: <details>" and skip to the result writing step.

4. **Execute the test case** following the steps, expected outcome, and any
   verification/cleanup sections in the test file. Use WDA for all UI
   interactions (refer to the ios-sim-navigation skill). Perform any REST API
   cleanup regardless of pass/fail.

5. **Write per-test result file** at
   `<PER_TEST_RESULTS_DIR>/<test-filename>.md`:

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

6. **End your response** with exactly one of these lines as the very last line:
    ```
    RESULT: PASS
    ```
    or:
    ```
    RESULT: FAIL: <reason>
    ```

IMPORTANT: Prefer the accessibility tree over screenshots. After every tap or
swipe, wait 0.5-1 seconds then re-fetch the tree to see the updated UI state.
````

#### Step 2: Parse subagent response

After the subagent returns, parse its response:

- Extract the last line for `RESULT: PASS` or `RESULT: FAIL: <reason>`.
- Update the in-context counters accordingly.

#### Step 3: Print status update

```
[2/5] PASS: create-blank-page
```
or:
```
[2/5] FAIL: create-blank-page — <reason>
```

## Phase 6: Cleanup and Assemble Results

1. Stop WDA:
   ```bash
   ruby ~/.claude/skills/ios-sim-navigation/scripts/wda-stop.rb
   ```

2. **Assemble the final results file** at `<base>/results/<timestamp>-<suite>.md`:
   - Read all per-test result files from `<base>/results/<timestamp>-<suite>/`
   - Sort them alphabetically by filename
   - Write the assembled file with this structure:
     ```
     # Test Results: <suite>

     - **Date:** <YYYY-MM-DD HH:mm>
     - **Site:** <site_url>
     - **Total:** N | **Passed:** P | **Failed:** F

     ## Results

     <contents of per-test result files, concatenated with blank lines between>
     ```

3. Print the final summary to the terminal:
   ```
   Test run complete.
   Total: N | Passed: P | Failed: F
   Results: <base>/results/<timestamp>-<suite>.md
   ```

## Important Notes

- The app MUST already be built and installed on a booted simulator. The app
  is relaunched and logged in if needed at the start of each test.
- Each test case runs in its own subagent to keep the main context lean.
  The subagent relaunches the app for a clean state before each test.
- Prefer the accessibility tree over screenshots for all simulator interactions.
- NEVER stop on a test failure. Always continue to the next test.
- After every tap or swipe, wait 0.5-1 seconds then re-fetch the accessibility
  tree to see the updated UI state.
- For scrolling, swipe from `(screen_width - 30, screen_height / 2)` upward
  to avoid accidentally tapping interactive elements in the center.
- Save failure screenshots to the derived screenshots directory (`<base>/results/screenshots/`).
- Each subagent writes its own per-test result file. The final results file is
  assembled in Phase 6 after all tests complete.
