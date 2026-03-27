---
name: ci-test-runner
description: >-
  CI-hardened single-test runner for WordPress/Jetpack iOS. Use when the prompt
  contains one test case and the available tools are the constrained Scripts/ci
  wrappers from Buildkite.
---

# CI Test Runner

Drive the app through one UI test case. Every response must contain tool calls.
Do not narrate plans — act.

## Commands

| Command | Purpose |
|---------|---------|
| `./Scripts/ci/launch-app.sh` | Relaunch app with test credentials |
| `./Scripts/ci/tap-element.sh IDENTIFIER_OR_LABEL` | Find element by accessibility ID or label and tap it (one call) |
| `./Scripts/ci/wda-curl.sh METHOD PATH [BODY]` | Raw WDA HTTP calls (for actions, typing, scrolling — see patterns below) |
| `./Scripts/ci/wp-api.sh PURPOSE METHOD PATH [BODY]` | REST API with purpose `setup`, `verification`, or `cleanup` |
| `./Scripts/ci/take-ai-test-screenshot.sh LABEL` | Screenshot (use only on failure) |
| `./Scripts/ci/record-ai-test-result.sh STATUS REASON [SCREENSHOT]` | Record final result — call exactly once |
| `sleep N` | Wait N seconds |

## WDA Patterns

Session ID is in `$WDA_SESSION_ID`.

### Fetch accessibility tree

```bash
./Scripts/ci/wda-curl.sh GET '/source?format=description'
```

Returns a text tree. Each element has type, frame `{{x, y}, {width, height}}`,
optional identifier and label. The root node frame gives screen dimensions.

### Tap element by ID or label (preferred — one call)

```bash
./Scripts/ci/tap-element.sh 'Prologue Self Hosted Button'
```

Finds the element by accessibility ID first, then by label as fallback, and
taps it. Use this for all taps where you know the identifier or label.

### Tap by coordinates (when no ID/label, or for precise positioning)

Compute center from frame: `X = x + width/2`, `Y = y + height/2`, then:

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/actions" \
  '{"actions":[{"type":"pointer","id":"f1","parameters":{"pointerType":"touch"},"actions":[{"type":"pointerMove","duration":0,"x":X,"y":Y},{"type":"pointerDown"},{"type":"pointerUp"}]}]}'
```

### Type text

Tap the field first to focus it, then:

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" \
  '{"value":["h","e","l","l","o"]}'
```

### Clear text field

Select all then delete:

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{"value":["\u0001"]}'
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/keys" '{"value":["\u007F"]}'
```

### Swipe / scroll

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/actions" \
  '{"actions":[{"type":"pointer","id":"f1","parameters":{"pointerType":"touch"},"actions":[{"type":"pointerMove","duration":0,"x":X1,"y":Y1},{"type":"pointerDown"},{"type":"pointerMove","duration":500,"x":X2,"y":Y2},{"type":"pointerUp"}]}]}'
```

- Scroll down: swipe from lower y to upper y. Use `x = screen_width - 30`.
- Back gesture: swipe from `(5, H/2)` to `(W*2/3, H/2)`.
- If the tree is unchanged after a scroll, you reached the end.

### Long press

Same as tap but add a pause between down and up:

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/actions" \
  '{"actions":[{"type":"pointer","id":"f1","parameters":{"pointerType":"touch"},"actions":[{"type":"pointerMove","duration":0,"x":X,"y":Y},{"type":"pointerDown"},{"type":"pause","duration":1000},{"type":"pointerUp"}]}]}'
```

### Press hardware button

```bash
./Scripts/ci/wda-curl.sh POST "/session/${WDA_SESSION_ID}/wda/pressButton" '{"name":"home"}'
```

## Test Flow

1. `./Scripts/ci/launch-app.sh`, then `sleep 3`, then fetch the tree.
2. If the tree shows a login/prologue screen, follow the Login Flow below.
   If already logged in (e.g., My Site tab visible), skip login.
3. Execute the test steps. After each action, `sleep 1` then fetch the tree
   to confirm the UI changed before proceeding.
4. Run verification with `./Scripts/ci/wp-api.sh verification ...` if required.
5. Run cleanup with `./Scripts/ci/wp-api.sh cleanup ...` if required.
6. Call `./Scripts/ci/record-ai-test-result.sh pass "Short reason"`.
   On failure, take a screenshot first and pass its path.

## Login Flow

1. `./Scripts/ci/tap-element.sh 'Prologue Self Hosted Button'`
2. `./Scripts/ci/tap-element.sh 'Site address'`
3. Type the site host (without scheme, e.g., `example.com`)
4. `./Scripts/ci/tap-element.sh 'Site Address Next Button'`
5. `sleep 3`, fetch tree — you should see the logged-in state

Never use the WordPress.com flow. Never type a password — it is passed via
launch arguments.

## Handling Common Situations

- **System alerts** (permissions, tracking): Check the tree for `Alert` or
  `Sheet` elements. Tap "Allow", "OK", or "Don't Allow" to dismiss, then retry.
- **Loading states**: If the tree shows a spinner, `sleep 2` and re-fetch.
- **Back navigation**: Tap the back button in the NavigationBar, or use the
  back swipe gesture as a fallback.
- **WDA session expired** (4xx errors): Create a new session:
  ```bash
  ./Scripts/ci/wda-curl.sh POST /session '{"capabilities":{"alwaysMatch":{}}}'
  ```
  Use `value.sessionId` from the response for subsequent calls.
- **App crash**: Re-run `./Scripts/ci/launch-app.sh`, `sleep 3`, re-fetch tree.

## Element Finding Priority

1. Accessibility identifier (most stable)
2. Label text
3. Type + context (e.g., Button inside NavigationBar)
4. Partial label match
5. Coordinates from the tree as last resort

## Rules

- **Act, don't narrate.** Every response must contain tool calls.
- **Use `tap-element.sh`** whenever you know the element's identifier or label.
  Fall back to coordinate taps only when there's no usable ID/label.
- **Screenshots only on failure.** Do not screenshot during normal flow.
- **Do not undo to recover from mistakes.** Move forward or fail the test.
  Only use undo/redo if the test case specifically asks for it.
- **Do not skip verification or cleanup** if the test case declares them.
- **Call record-ai-test-result.sh exactly once.** Keep the reason short and
  single-line.
