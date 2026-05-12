---
name: ios-sim-navigation
description: General-purpose skill for navigating and interacting with an iOS app running in a Simulator using WebDriverAgent (WDA). Use when the user asks to tap buttons, swipe, scroll, type text, check what's on screen, go to a tab or screen, automate a flow, or verify UI state in a simulator app. Also use when the user wants to take screenshots, inspect the accessibility tree, explore screen hierarchy, or test a UI flow end-to-end on a simulator. Even if the user says something casual like "open settings in the app", "click that button", or "what's showing on the simulator" — this skill applies.
---

# iOS Simulator Navigation with WebDriverAgent

## Prerequisites

- Xcode with iOS Simulators installed
- WebDriverAgent built for simulator use (see Setup below)
- The app must be built and installed on the target simulator

### First-Time Setup

Clone and build WebDriverAgent:

```bash
mkdir -p .build
git clone https://github.com/appium/WebDriverAgent.git .build/WebDriverAgent
cd .build/WebDriverAgent
xcodebuild build-for-testing \
  -project WebDriverAgent.xcodeproj \
  -scheme WebDriverAgentRunner \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  CODE_SIGNING_ALLOWED=NO
```

## WDA Lifecycle

Start and stop WDA using the lifecycle scripts. **WDA must be running before using any curl commands below.**

```bash
# Start WDA (waits until ready, ~60s first time)
ruby scripts/wda-start.rb [--udid <UDID>] [--port <PORT>]

# Check if WDA is running
curl -s http://localhost:8100/status | head -c 200

# Stop WDA
ruby scripts/wda-stop.rb [--port <PORT>]
```

Both scripts auto-detect the first booted simulator. Use `--udid` to target a specific one.

## Strategy: Tree-First Navigation

**Always prefer the accessibility tree over screenshots.** The tree is text-based, faster to process, and doesn't require viewing an image.

1. Fetch the tree with `GET /source?format=description`
2. Make decisions from the tree alone
3. Only take a screenshot when the tree doesn't contain enough info (e.g., verifying visual layout)

## Accessibility Tree

WDA offers two tree formats via `GET /source?format=<FORMAT>`:

### `format=description` -- compact plaintext (~25 KB)

```bash
curl -s 'http://localhost:8100/source?format=description' | jq -r .value
```

Returns a human-readable indented tree. Each line shows an element with its type, memory address, frame as `{{x, y}, {width, height}}`, and optional attributes (identifier, label, Selected, etc.):

```
NavigationBar, 0x105351660, {{0.0, 62.0}, {402.0, 54.0}}, identifier: 'my-site-navigation-bar'
  Button, 0x105351a20, {{16.0, 62.0}, {44.0, 44.0}}, identifier: 'BackButton', label: 'Site Name'
  StaticText, 0x105351b40, {{178.7, 73.7}, {44.7, 20.7}}, label: 'Posts'
```

**Use this format by default.** It's ~15x smaller than JSON, easy to reason about, and contains all the information needed for navigation (types, labels, identifiers, and coordinates).

### `format=json` -- structured data (~375 KB)

```bash
curl -s 'http://localhost:8100/source?format=json' > /tmp/wda-tree.json
```

Returns deeply nested JSON. Use this when you need to programmatically extract coordinates or search for elements with `jq`. The response has the structure `{"value": <root_node>, "sessionId": "..."}`. Each node has:

| Field | Description |
|-------|-------------|
| `type` | Element type (e.g., `Button`, `StaticText`, `NavigationBar`) |
| `label` | Accessibility label (user-visible text) |
| `name` | Accessibility identifier (developer-assigned ID) |
| `value` | Current value (e.g., text field contents, switch state) |
| `rect` | `{"x": N, "y": N, "width": N, "height": N}` -- structured, use for tap coordinates |
| `frame` | Same as rect but as a string: `"{{x, y}, {w, h}}"` |
| `isEnabled` | Whether the element is interactive |
| `children` | Array of child nodes |

Search example with `jq`:

```bash
cat /tmp/wda-tree.json | jq '.. | objects | select(.label == "Settings")'
```

### Computing Tap Coordinates

From the description format, parse the frame `{{x, y}, {width, height}}` and compute:

```
tap_x = x + width / 2
tap_y = y + height / 2
```

From the JSON format, use the `rect` object:

```
tap_x = rect.x + rect.width / 2
tap_y = rect.y + rect.height / 2
```

### Finding Elements

Use this priority order when locating elements in the tree:

1. **`identifier` / `name`** -- most stable; developer-assigned, unlikely to change across locales
2. **`label`** -- accessibility label; user-visible text, may change with localization
3. **`type` + context** -- e.g., "Button inside NavigationBar" or "Cell inside Table"
4. **Partial matching** -- element label *contains* the target text (useful for dynamic labels like "3 Posts")
5. **Positional heuristics** -- last resort; fragile across screen sizes

In the description format, search the text output for labels or identifiers. In the JSON format, use `jq`:

```bash
# Exact match by identifier
cat /tmp/wda-tree.json | jq '.. | objects | select(.name == "settings-button")'

# Exact match by label
cat /tmp/wda-tree.json | jq '.. | objects | select(.label == "Settings")'

# Partial match by label
cat /tmp/wda-tree.json | jq '.. | objects | select(.label? // "" | contains("Settings"))'

# Type + context: find Buttons inside NavigationBar
cat /tmp/wda-tree.json | jq '.. | objects | select(.type == "NavigationBar") | .. | objects | select(.type == "Button")'
```

### Screen Size

The root node's `rect` gives the screen dimensions (e.g., `width: 393, height: 852`).

## Session Management

Most action endpoints require a session ID. Create one if `/status` doesn't return a `sessionId`:

```bash
# Create session
curl -s -X POST http://localhost:8100/session \
  -H 'Content-Type: application/json' \
  -d '{"capabilities":{"alwaysMatch":{}}}' | jq .
```

The session ID is at `value.sessionId` in the response. Use it in subsequent action URLs as `SESSION_ID`.

To check for an existing session, look at the `sessionId` field in the `/status` response.

## Actions

All action endpoints use `POST /session/SESSION_ID/actions` with W3C WebDriver pointer actions.

### Tap

```bash
curl -s -X POST http://localhost:8100/session/SESSION_ID/actions \
  -H 'Content-Type: application/json' \
  -d '{
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

#### Alternative: Element-Based Tapping

WDA can find and tap elements directly without computing coordinates. This is useful when an element has a stable accessibility identifier:

```bash
# Find the element by accessibility identifier
curl -s -X POST http://localhost:8100/session/SESSION_ID/elements \
  -H 'Content-Type: application/json' \
  -d '{"using": "accessibility id", "value": "settings-button"}' | jq .

# Tap it (ELEMENT_ID comes from the response above, at value[0].ELEMENT)
curl -s -X POST http://localhost:8100/session/SESSION_ID/element/ELEMENT_ID/click
```

The coordinate approach above is preferred because it works directly with the tree data already being fetched. Use element-based tapping when coordinate parsing is awkward or when interacting with elements found by predicate.

### Long Press

Add a `pause` between `pointerDown` and `pointerUp`. Duration is in milliseconds.

```bash
curl -s -X POST http://localhost:8100/session/SESSION_ID/actions \
  -H 'Content-Type: application/json' \
  -d '{
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

Move from `(x1, y1)` to `(x2, y2)` with a duration (milliseconds) on the second `pointerMove`.

```bash
curl -s -X POST http://localhost:8100/session/SESSION_ID/actions \
  -H 'Content-Type: application/json' \
  -d '{
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
- **Back** (swipe from left edge): from `(5, H/2)` to `(W*2/3, H/2)`

### Back Navigation

To go back to the previous screen:

- **Primary**: find a Button inside NavigationBar -- its label is typically the previous screen's title. Tap it.
- **Fallback**: edge swipe from `(5, H/2)` to `(W*2/3, H/2)` (see Swipe direction guide above)

The button approach is more reliable because edge swipes can be finicky depending on gesture recognizers.

### Type Text

```bash
curl -s -X POST http://localhost:8100/session/SESSION_ID/wda/keys \
  -H 'Content-Type: application/json' \
  -d '{"value": ["h","e","l","l","o"]}'
```

The `value` array contains individual characters. An element must be focused first (tap a text field before typing).

### Clear Text Field

Select all text and delete it:

```bash
# Select all (Ctrl+A) then delete
curl -s -X POST http://localhost:8100/session/SESSION_ID/wda/keys \
  -H 'Content-Type: application/json' \
  -d '{"value": ["\u0001"]}'
curl -s -X POST http://localhost:8100/session/SESSION_ID/wda/keys \
  -H 'Content-Type: application/json' \
  -d '{"value": ["\u007F"]}'
```

Alternatively, if you have an element ID:

```bash
curl -s -X POST http://localhost:8100/session/SESSION_ID/element/ELEMENT_ID/clear
```

## Waiting for UI Stability

After performing an action (tap, swipe, type), the UI may be animating or loading. Instead of using a fixed sleep, poll for the expected state:

1. Fetch the accessibility tree
2. Check if the expected element or screen is present
3. If not found, sleep 0.5s and retry
4. After 10 failed attempts (5 seconds total), declare the element not found

This approach is more reliable than fixed delays because it adapts to variable animation durations and network load times.

## Scroll View Navigation

To find an element in a long scrollable list:

1. Fetch the tree and search for the target element
2. If found, tap it -- done
3. If not found, swipe up from the right edge to scroll down (use x = `screen_width - 30` to avoid tapping interactive elements)
4. Re-fetch the tree and search again
5. **Detect end of list**: if the tree content is identical after a scroll, you've reached the bottom
6. Stop and report element not found if the bottom is reached without finding the target

Use the same pattern for horizontal scroll views, adjusting swipe direction accordingly.

## Screenshots

Use `simctl` for screenshots -- more reliable than WDA's base64 approach:

```bash
xcrun simctl io <UDID> screenshot /tmp/screenshot.png
```

To get the booted simulator's UDID:

```bash
xcrun simctl list devices booted -j | jq -r '.devices | to_entries[].value[] | select(.state == "Booted")'
```

## Tips

- **Tree coordinates, not screenshot pixels** -- screenshots may be at a different resolution than the tree's point-based coordinates.
- **Vertical swipes**: use the right edge x-coordinate (`screen_width - 30`) to avoid accidentally tapping interactive elements in the center. Use center only when needed.
- **Slow swipes on tappable items**: swipe gestures on tappable items may register as a tap. Use `duration: 1000` (1 second) for more reliable swipes.
- **WDA startup time**: ~60s the first time. Subsequent starts are faster with cached DerivedData.
- **Reconnecting**: if WDA disconnects, run `wda-start.rb` again -- it will reconnect.
- **Tab bar**: look for elements with type containing `TabBar` in the tree. Its children are the individual tabs.

## Common Failures and Recovery

### WDA Session Expiry

WDA sessions can expire after inactivity. If action requests return HTTP 4xx errors, re-create the session:

```bash
curl -s -X POST http://localhost:8100/session \
  -H 'Content-Type: application/json' \
  -d '{"capabilities":{"alwaysMatch":{}}}' | jq .
```

### Stale Element Coordinates

After animations or screen transitions, previously fetched coordinates may be wrong. Always re-fetch the tree and recompute coordinates before tapping after any navigation action.

### System Alert Interception

System alerts (location permissions, notification permissions, tracking prompts) can block interactions with the app. Before retrying a failed tap:

1. Fetch the tree and look for elements of type `Alert` or `Sheet`
2. If found, look for a dismiss button ("Allow", "Don't Allow", "OK", "Cancel") and tap it
3. Then retry the original action

### App Crash Detection

If actions consistently fail or the tree looks unexpected, the app may have crashed. Check and re-launch:

```bash
# Check if the app process is running
xcrun simctl list devices booted

# Re-launch the app
xcrun simctl launch <UDID> <APP_BUNDLE_ID>
```

After re-launching, create a new WDA session before continuing.
