---
name: ci-test-runner
description: >-
  CI-hardened E2E test runner for WordPress/Jetpack iOS. Use when the prompt
  mentions "ci-test-runner" or asks to run AI E2E tests in CI mode. Drives
  the iOS Simulator through wrapper scripts with a locked-down tool set.
---

# CI Test Runner

Run plain-language E2E test cases against the WordPress or Jetpack iOS app
on an iOS Simulator. All external interactions use wrapper scripts — no raw
curl, no arbitrary shell commands.

## Environment

All values are pre-set as environment variables by the CI script. You do NOT
need to ask for credentials or configure anything.

| Env var | Description |
|---------|-------------|
| `SIMULATOR_UDID` | Booted simulator UDID |
| `WDA_SESSION_ID` | Active WebDriverAgent session ID |
| `WDA_PORT` | WDA port (default 8100) |
| `APP_BUNDLE_ID` | `org.wordpress` or `com.automattic.jetpack` |
| `SITE_URL` | WordPress test site URL |
| `WP_USERNAME` | WordPress username |
| `WP_APP_PASSWORD` | WordPress application password |

These are also read by the wrapper scripts, so you do not need to pass
credentials as command arguments.

## Available Commands

You have exactly these commands available:

| Command | Purpose |
|---------|---------|
| `./Scripts/ci/wda-curl.sh METHOD PATH [BODY]` | HTTP to WDA (localhost only) |
| `./Scripts/ci/wp-api.sh METHOD PATH [BODY]` | WordPress REST API (auth handled) |
| `./Scripts/ci/launch-app.sh` | (Re)launch app with test credentials |
| `xcrun simctl terminate $SIMULATOR_UDID $APP_BUNDLE_ID` | Kill app |
| `xcrun simctl io $SIMULATOR_UDID screenshot PATH` | Take screenshot |
| `sleep N` | Wait N seconds |
| `mkdir -p Tests/AgentTests/results/...` | Create results directories |

## WDA Interactions

WDA is already running. A session ID is in the `WDA_SESSION_ID` env var and
also provided in the prompt.

### Get Accessibility Tree

```bash
# Compact text format (~25 KB) — use this by default
./Scripts/ci/wda-curl.sh GET '/source?format=description'

# Structured JSON (~375 KB) — use when you need precise rect coordinates
./Scripts/ci/wda-curl.sh GET '/source?format=json'
```

**Note:** `wda-curl.sh` returns raw JSON. The tree content is inside the
`value` field. For the description format, parse the `value` string from the
JSON response to get the indented tree text.

The description format returns lines like:
```
NavigationBar, 0x105351660, {{0.0, 62.0}, {402.0, 54.0}}, identifier: 'my-site-navigation-bar'
  Button, 0x105351a20, {{16.0, 62.0}, {44.0, 44.0}}, identifier: 'BackButton', label: 'Site Name'
  StaticText, 0x105351b40, {{178.7, 73.7}, {44.7, 20.7}}, label: 'Posts'
```

### Computing Tap Coordinates

Parse the frame `{{x, y}, {width, height}}` from the description tree:

```
tap_x = x + width / 2
tap_y = y + height / 2
```

### Session Management

If WDA actions return HTTP 4xx errors, the session may have expired. Create
a new one:

```bash
./Scripts/ci/wda-curl.sh POST /session '{"capabilities":{"alwaysMatch":{}}}'
```

Extract `value.sessionId` from the JSON response and use it in subsequent
action paths.

### Tap

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/actions" '{
  "actions": [{
    "type": "pointer",
    "id": "finger1",
    "parameters": {"pointerType": "touch"},
    "actions": [
      {"type": "pointerMove", "duration": 0, "x": X, "y": Y},
      {"type": "pointerDown"},
      {"type": "pointerUp"}
    ]
  }]
}'
```

### Tap Element by Accessibility ID

```bash
# Find element
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/elements" '{
  "using": "accessibility id",
  "value": "IDENTIFIER"
}'

# Click it (ELEMENT_ID from response value[0].ELEMENT)
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/element/${ELEMENT_ID}/click"
```

### Long Press

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/actions" '{
  "actions": [{
    "type": "pointer",
    "id": "finger1",
    "parameters": {"pointerType": "touch"},
    "actions": [
      {"type": "pointerMove", "duration": 0, "x": X, "y": Y},
      {"type": "pointerDown"},
      {"type": "pause", "duration": 1000},
      {"type": "pointerUp"}
    ]
  }]
}'
```

### Swipe

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/actions" '{
  "actions": [{
    "type": "pointer",
    "id": "finger1",
    "parameters": {"pointerType": "touch"},
    "actions": [
      {"type": "pointerMove", "duration": 0, "x": X1, "y": Y1},
      {"type": "pointerDown"},
      {"type": "pointerMove", "duration": 500, "x": X2, "y": Y2},
      {"type": "pointerUp"}
    ]
  }]
}'
```

**Swipe direction guide** (given screen size `W x H`):
- **Up** (scroll down): from `(W/2, H/2 + H/6)` to `(W/2, H/2 - H/6)`
- **Down** (scroll up): from `(W/2, H/2 - H/6)` to `(W/2, H/2 + H/6)`
- **Left**: from `(W/2 + W/4, H/2)` to `(W/2 - W/4, H/2)`
- **Right**: from `(W/2 - W/4, H/2)` to `(W/2 + W/4, H/2)`
- **Back** (from left edge): from `(5, H/2)` to `(W*2/3, H/2)`

### Type Text

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{
  "value": ["h","e","l","l","o"]
}'
```

An element must be focused first (tap a text field before typing).

### Clear Text Field

```bash
# Select all (Ctrl+A)
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{"value": ["\u0001"]}'
# Delete
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{"value": ["\u007F"]}'
```

### Press Hardware Button

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/pressButton" '{"name": "home"}'
```

## WordPress REST API

Use `wp-api.sh` for all REST API calls. Authentication is handled by the
script — do not pass credentials.

```bash
# Search for a post
./Scripts/ci/wp-api.sh GET 'wp/v2/posts?search=My+Post&status=publish'

# Create a category
./Scripts/ci/wp-api.sh POST wp/v2/categories '{"name":"Test Category"}'

# Delete a post (force = skip trash)
./Scripts/ci/wp-api.sh DELETE 'wp/v2/posts/123?force=true'

# Create a tag
./Scripts/ci/wp-api.sh POST wp/v2/tags '{"name":"Test Tag"}'
```

## Navigation Strategy

**Always prefer the accessibility tree over screenshots.**

### Finding Elements

Use this priority order:
1. **`identifier` / `name`** — most stable, developer-assigned
2. **`label`** — accessibility label, user-visible text
3. **`type` + context** — e.g., "Button inside NavigationBar"
4. **Partial matching** — label contains target text
5. **Positional heuristics** — last resort

### Screen Size

The root node's frame in the tree gives screen dimensions (e.g., `{{0, 0}, {393, 852}}`).

### Waiting for UI Stability

After every action (tap, swipe, type), wait 0.5–1 second then re-fetch the
tree. Do not use fixed long sleeps. Instead, poll:

1. Fetch the tree
2. Check if expected element or screen is present
3. If not, `sleep 1` and retry
4. After 10 retries (10 seconds), declare element not found

### Scroll View Navigation

1. Fetch tree, search for target element
2. If found, tap it
3. If not, swipe up from `(screen_width - 30, screen_height / 2)` to scroll
4. Re-fetch tree and search again
5. If tree is identical after scroll, you've hit the bottom — stop

### Back Navigation

- **Primary**: find a Button inside NavigationBar, tap it
- **Fallback**: edge swipe from `(5, H/2)` to `(W*2/3, H/2)`

### Tab Bar Navigation

Look for elements with type containing `TabBar` in the tree. Its children
are the individual tabs. Tap the tab you need to switch to.

### System Alert Handling

If actions fail, check the tree for `Alert` or `Sheet` elements. Dismiss
with "Allow", "Don't Allow", "OK", or "Cancel" before retrying.

### App Crash Recovery

If the tree looks unexpected or actions consistently fail:
1. Relaunch with `./Scripts/ci/launch-app.sh`
2. Wait 3 seconds
3. Create a new WDA session if needed
4. Continue the test

## Test Execution Flow

### Step 1: Discover Tests

Use `Glob` to find all `*.md` files in the test directory provided in the
prompt. Sort alphabetically. Print:

```
Discovered N test(s):
- create-blank-page.md
- text-post-publish.md
```

If none found, write a results.md noting this and stop.

### Step 2: Initialize

The results directory is provided in the prompt. Create subdirectories:

```bash
mkdir -p ${RESULTS_DIR}/screenshots
```

### Step 3: Run Each Test Sequentially

For each test file:

#### 3a. Relaunch app

```bash
./Scripts/ci/launch-app.sh
sleep 3
```

#### 3b. Check login state

Fetch the tree. If the app shows a login screen:
1. Tap "Enter your existing site address"
2. Type the site URL (from the prompt)
3. Tap Continue
4. Wait 3 seconds for auto-login

If the app shows the logged-in state (My Site), skip login.

#### 3c. Read test file

Use `Read` to get the test case markdown. Parse the sections:
- **Prerequisites** — setup steps (REST API or UI)
- **Steps** — actions to perform
- **Verification (REST API)** — REST API assertions (if present)
- **Cleanup (REST API)** — REST API cleanup (if present)
- **Expected Outcome** — what success looks like

#### 3d. Fulfill prerequisites

For REST API prerequisites (create categories, tags, posts), use
`./Scripts/ci/wp-api.sh`. For UI prerequisites like "logged in", the
relaunch in 3a handles it.

If a prerequisite cannot be fulfilled, mark the test as FAIL with reason
"Prerequisite not met: <details>" and skip directly to step 3h (record
result).

#### 3e. Execute steps

Follow the numbered steps using WDA commands. After each action, wait
briefly and re-fetch the tree to verify the UI changed as expected.

#### 3f. Verify (if section present)

If the test has a `## Verification (REST API)` section, use `wp-api.sh`
to verify. The verification MUST succeed for the test to pass.

#### 3g. Cleanup (if section present)

If the test has a `## Cleanup (REST API)` section, use `wp-api.sh` to
clean up. Always run cleanup regardless of pass/fail.

#### 3h. Record result

Write a per-test result file at `${RESULTS_DIR}/<test-name>.md`:

On pass:
```
### PASS: <Test Title>
Passed.
```

On fail — take a screenshot first:
```bash
xcrun simctl io $SIMULATOR_UDID screenshot Tests/AgentTests/results/${TIMESTAMP}/screenshots/<test-name>-failure.png
```
Then write:
```
### FAIL: <Test Title>
**Reason:** <what went wrong>
**Screenshot:** screenshots/<test-name>-failure.png
```

#### 3i. Print status

```
[2/5] PASS: create-blank-page
```
or:
```
[2/5] FAIL: create-blank-page — Element "Publish" not found
```

### Step 4: Assemble Final Results

Read all per-test result files. Write `${RESULTS_DIR}/results.md`:

```markdown
# Test Results

- **Date:** YYYY-MM-DD HH:mm
- **App:** <app name>
- **Site:** <site_url>
- **Total:** N | **Passed:** P | **Failed:** F

## Results

<per-test results concatenated>
```

### Step 5: Print Summary

```
Test run complete.
Total: N | Passed: P | Failed: F
Results: Tests/AgentTests/results/<timestamp>/results.md
```

## Important Rules

- **The app MUST already be built and installed** on the simulator. The CI
  pipeline handles building. This skill only drives tests.
- **NEVER stop on failure.** Always continue to the next test.
- **Always run cleanup** regardless of pass/fail.
- **Prefer the accessibility tree** over screenshots for navigation.
- **After every action**, wait 0.5–1s then re-fetch the tree.
- **For scrolling**, swipe from the right edge (`screen_width - 30`) to
  avoid tapping interactive elements.
- **Use `duration: 1000`** (1 second) for swipes on tappable items.
- **Coordinates are in points**, not pixels — use tree coordinates, not
  screenshot dimensions.
