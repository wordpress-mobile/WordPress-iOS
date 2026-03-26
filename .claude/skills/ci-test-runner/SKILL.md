---
name: ci-test-runner
description: >-
  CI-hardened single-test runner for WordPress/Jetpack iOS. Use when the prompt
  contains one test case and the available tools are the constrained Scripts/ci
  wrappers from Buildkite.
---

# CI Test Runner

Run exactly one markdown UI test case against the WordPress or Jetpack iOS app
in a booted simulator. The shell runner owns test discovery, result assembly,
and contract enforcement. Your job is to drive the app and record one final
result for the current test.

## Environment

All values are pre-set by the shell runner:

| Env var | Description |
|---------|-------------|
| `SIMULATOR_UDID` | Booted simulator UDID |
| `WDA_SESSION_ID` | Active WebDriverAgent session ID for this test |
| `WDA_PORT` | WDA port |
| `APP_BUNDLE_ID` | `org.wordpress` or `com.automattic.jetpack` |
| `SITE_URL` | WordPress test site URL |
| `WP_USERNAME` | WordPress username |
| `AI_TEST_TITLE` | Current test title |

The current test case markdown is included in the prompt. Use that content
directly instead of trying to locate the file on disk.

Do not ask for credentials or try to read files directly.

## Available Commands

You have exactly these commands available:

| Command | Purpose |
|---------|---------|
| `./Scripts/ci/launch-app.sh` | Relaunch app with test credentials and UI-test flags |
| `./Scripts/ci/wda-curl.sh METHOD PATH [BODY]` | Allowed WDA calls only |
| `./Scripts/ci/wp-api.sh PURPOSE METHOD PATH [BODY]` | REST API calls with purpose `setup`, `verification`, or `cleanup` |
| `./Scripts/ci/take-ai-test-screenshot.sh LABEL` | Capture a failure screenshot and print its relative path |
| `./Scripts/ci/record-ai-test-result.sh STATUS REASON [SCREENSHOT]` | Record the final `pass` or `fail` result |
| `sleep N` | Wait for UI stability |

## WDA Interactions

WDA is already running. A session ID is in `WDA_SESSION_ID`.

### Get Accessibility Tree

```bash
# Compact text format — use this by default
./Scripts/ci/wda-curl.sh GET '/source?format=description'

# Structured JSON — only when you truly need precise rect coordinates
./Scripts/ci/wda-curl.sh GET '/source?format=json'
```

The tree content is inside the JSON `value` field.

### Computing Tap Coordinates

Parse a frame like `{{x, y}, {width, height}}` from the tree:

```text
tap_x = x + width / 2
tap_y = y + height / 2
```

### Session Management

If WDA starts returning 4xx session errors, create a fresh session:

```bash
./Scripts/ci/wda-curl.sh POST /session '{"capabilities":{"alwaysMatch":{}}}'
```

Extract `value.sessionId` from the JSON response and use it in later paths.

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
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/elements" '{
  "using": "accessibility id",
  "value": "IDENTIFIER"
}'
```

Then click the returned element with:

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/element/${ELEMENT_ID}/click"
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

For vertical scrolling, use `x = screen_width - 30` to avoid hitting tappable UI.

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

### Type Text

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{
  "value": ["h","e","l","l","o"]
}'
```

Tap a text field first so it has focus.

### Clear Text Field

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{"value": ["\u0001"]}'
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{"value": ["\u007F"]}'
```

### Press Hardware Button

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/pressButton" '{"name": "home"}'
```

## Navigation Strategy

Always prefer the accessibility tree over screenshots.

### Finding Elements

Use this priority order:
1. Accessibility identifier
2. Visible label text
3. Type plus surrounding context
4. Partial label matching
5. Positional heuristics as a last resort

### Waiting for UI Stability

After every action:
1. Wait briefly, usually `sleep 1`
2. Re-fetch the tree
3. Confirm the expected screen or element is now present

Do not rely on long blind sleeps when polling is enough.

### Scroll View Navigation

1. Fetch the tree and search for the target element.
2. If found, tap it.
3. If not, swipe up from the right edge.
4. Re-fetch the tree and search again.
5. If the tree is unchanged after a scroll, assume you reached the end.

### Screen Size

Use the root node frame from the tree to derive screen dimensions.

### Back Navigation

- Primary: tap a navigation bar back button
- Fallback: swipe from the left edge toward the center

### Tab Bar Navigation

Look for `TabBar` elements in the tree and tap the needed tab.

### System Alert Handling

If actions fail unexpectedly, check for `Alert` or `Sheet` elements and dismiss
them before retrying.

### App Crash Recovery

If the tree looks wrong or actions consistently fail:
1. Relaunch with `./Scripts/ci/launch-app.sh`
2. Wait 3 seconds
3. Re-fetch the tree
4. Create a new WDA session if the old one expired

## Single-Test Flow

1. Start with `./Scripts/ci/launch-app.sh`, then `sleep 3`, then inspect the tree.
2. Read the current test case carefully. It may include `Prerequisites`, `Steps`, `Verification`, `Cleanup`, `Expected Outcome`, or similar sections.
3. Fulfill prerequisites using UI actions or `wp-api.sh setup ...`.
4. If a prerequisite cannot be fulfilled, fail the test with reason `Prerequisite not met: <details>`.
5. Execute the numbered test steps, verifying UI changes after each action.
6. Use the expected outcome to confirm you reached the intended end state.
7. Run any verification work with `wp-api.sh verification ...`.
8. Run any cleanup work with `wp-api.sh cleanup ...`, even after failures.
9. If the test fails, take a screenshot first and pass the returned relative path into `record-ai-test-result.sh`.
10. Call `record-ai-test-result.sh` exactly once before stopping. Always pass a reason; `Passed.` is enough for a normal pass.
11. Keep the recorded reason short and single-line.

## Login Constraints

- This CI flow is for a self-hosted site login path.
- The app may already be logged in. If the tree already shows the logged-in state, skip login.
- Prefer the self-hosted site address flow.
- If a login screen is shown, tap `Enter your existing site address`, type the site URL, tap continue, then wait 2-3 seconds and re-fetch the tree for the logged-in state.
- Do not switch into a WordPress.com email/password flow unless the test case explicitly requires it.
- Do not invent credentials or ask for them.

## Important Rules

- The app is expected to already be built and installed on the simulator.
- Never try to read or write arbitrary files.
- Never call `record-ai-test-result.sh` more than once.
- Never skip declared verification or cleanup work.
- Never use screenshots as the primary navigation source when the tree is enough.
