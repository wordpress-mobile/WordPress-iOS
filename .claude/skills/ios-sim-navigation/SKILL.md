---
name: ios-sim-navigation
description: Drive an iOS app running in a Simulator via WebDriverAgent (WDA) — tap, swipe, scroll, type, take screenshots, inspect the accessibility tree, automate or verify a UI flow. Use when the work specifically targets a running Simulator app (e.g. running an end-to-end test, automating an in-app flow, verifying on-screen state via the WDA tree, scripting taps in a simulator). Do not use for non-Simulator UI work, headless code paths, or UI tasks on real devices.
---

# iOS Simulator Navigation with WebDriverAgent

Drive an iOS app running in a Simulator via WebDriverAgent (WDA).

## Fast-Path Cadence — read this first

End-to-end test runs have a hard time budget — usually a few minutes per
test. Every tool call costs roughly 5 s of WDA + Claude round-trip
overhead, so **keep each user-visible action to about one tool call**.
The patterns below — use `tap.rb` over raw curl, never `Read` PNG
screenshots, one tree dump per screen — compound across a long test to
keep you inside the budget. The inverse patterns (three curl turns per
tap, `Read`-ing screenshot PNGs, re-dumping the tree after every action)
burn it.

### Rule 1 — One bash call per tap. Always reach for `scripts/tap.rb`.

`tap.rb` does session creation, element lookup, coordinate computation,
the tap, and an in-band readiness probe in a single Ruby invocation:

```bash
# Tap a control AND wait up to 3 s for the next screen's marker to appear.
# Replaces: find /elements + get /rect + POST /actions + sleep + tree dump.
ruby scripts/tap.rb aid "create-post-button" --wait-aid "post-title-field"
```

If you find yourself stringing together `/elements`, `/rect`, and
`/actions` curls by hand, stop. You're about to burn three turns on what
one `tap.rb` invocation does. Reach for raw curl only for genuinely
custom gestures (multi-touch, long-press chains) that `tap.rb` doesn't
model.

### Rule 2 — Never `Read` a screenshot PNG back into context.

Decisions come from the **accessibility tree (text)**, not images. Pulling
a PNG back through `Read` inflates the conversation by megabytes per turn
*and* burns an extra round-trip. The tree already contains every label,
identifier, and coordinate you'd see in the screenshot. Screenshots are
an output artifact (failure capture for human review), never an input to
your reasoning. If you're about to `Read /tmp/*.png`, you've already gone
wrong: re-fetch the tree instead.

### Rule 3 — One tree dump per screen, not per action.

Fetch `GET /source?format=description` once when you arrive on a new
screen. From that single dump, locate every control you need for the
screen (FAB, fields, buttons), then drive the screen with `tap.rb`.
`tap.rb` itself probes `/elements` for each individual tap, so you do
**not** need to re-dump the full tree between taps. The wait flag is your
between-tap confirmation, not a re-dump.

Re-dump the tree only when (a) you've landed on a screen you haven't
seen yet this run, or (b) `--wait-aid` timed out and you genuinely need
to figure out what's on screen.

### Anti-pattern: the slow loop

```
# DON'T do this — 4 turns per action, plus megabytes of PNG.
ruby scripts/tap.rb aid create-post-button
xcrun simctl io <UDID> screenshot /tmp/after.png
Read /tmp/after.png
curl -s 'http://localhost:8100/source?format=description' | jq -r .value
```

```
# DO this — 1 turn, no PNG, in-band verification.
ruby scripts/tap.rb aid create-post-button --wait-aid post-title-field
```

A test case that says "Verify the post-publish confirmation screen shows
the correct title" is asking you to confirm that text via the tree (a
single targeted `/elements` query by label, or one tree dump and grep),
not to take a picture of it. See "Verifying step success" below.

## Prerequisites

- Xcode with iOS Simulators installed
- The app must be built and installed on the target simulator

## WDA Lifecycle

Start and stop WDA using the lifecycle scripts. **WDA must be running before using any curl commands below.**

```bash
# Start WDA. Cold runs do the build first (minutes); warm runs ~60s.
ruby scripts/wda-start.rb [--udid <UDID>] [--port <PORT>]

# Check if WDA is running
curl -s http://localhost:8100/status | head -c 200

# Stop WDA
ruby scripts/wda-stop.rb [--port <PORT>]
```

Both scripts auto-detect the first booted simulator. Use `--udid` to target a specific one.

Run these from the project root that should own the
`.build/WebDriverAgent` cache. `wda-start.rb` resolves the path
relative to its working directory and clones into it on first run.

## Launching the app with custom options (caller-supplied)

By default you don't launch the app yourself — the first `tap.rb` binds a
session to whatever app is in the foreground. But some callers need the app
launched with **specific launch arguments or environment variables**: test
configuration, feature flags, or instrumentation that an external instrument
reads from the app's environment (a profiler, a leak detector, etc.).

This skill is agnostic about *what* those options are. It just gives the caller
a way to inject them: launch the app through WDA with `scripts/wda-session.rb`
**before** any `tap.rb` call, so the instrumented process is the one WDA drives.

```bash
# Launch arguments (order-preserving; a `-key value` pair is two --arg tokens).
ruby scripts/wda-session.rb --bundle com.example.app --arg -some-flag --arg value

# Environment variables (e.g. to enable an instrument the caller cares about).
ruby scripts/wda-session.rb --bundle com.example.app --env SOME_INSTRUMENT_VAR=1
```

Don't substitute `simctl launch` for this — its options are silently discarded
when WDA binds the session. Establish the `wda-session.rb` session first, then
drive normally; don't `simctl launch` again or delete the session file mid-run
(either relaunches the app without the options). `references/sessions.md`
explains why.

## Tap — the default action

**Use `scripts/tap.rb` for every tap.** It collapses session creation
(with the required `bundleId` binding — see `references/sessions.md`),
element lookup, coordinate computation, the tap dispatch, and an
optional wait into one bash invocation. Three forms:

```bash
# Tap by accessibility id (most reliable; developer-assigned, locale-stable).
ruby scripts/tap.rb aid settings-button

# Tap by visible label (matches accessibility id OR label).
ruby scripts/tap.rb text "Continue"

# Tap at exact coordinates (only when no stable id/label exists,
# e.g. tapping into an empty area to dismiss a sheet).
ruby scripts/tap.rb at 196,504
```

### `--wait-aid` / `--wait-text` — fuse tap and verification

After most taps you need to confirm the next screen is up before the
next action. When you can name an element you're confident will appear,
pass it to `tap.rb` and let the wait happen in the same call:

```bash
# Tap, then wait up to 3s for "Site address" field to appear. ONE turn.
ruby scripts/tap.rb aid "Prologue Self Hosted Button" --wait-aid "Site address"

# Tab-switch: wait for a known element on the destination screen.
ruby scripts/tap.rb aid tabbar_mysites --wait-aid switch-site-button

# Wait by visible label instead of aid.
ruby scripts/tap.rb text "Continue" --wait-text "My Site"

# Bump --timeout for known-slow transitions (network, large lists).
ruby scripts/tap.rb aid publish-button --wait-aid "Post Published" --timeout 15
```

The wait polls `/elements` every 250 ms (cheap probe, ~200 B per response)
and exits as soon as the target appears.

**When to use the wait flag.** Use it whenever you can plausibly name
something on the next screen. Even if you're not 100% sure of the
identifier, naming the most likely candidate is still cheaper than
tapping plain and re-dumping the tree. The downside of a wrong guess is
small: the wait times out (default 3 s) and `tap.rb` exits 1, at which
point you fall back to a tree dump. The upside on a right guess is
saving 2-3 turns.

**Naming hints**
- `--wait-aid` matches the developer-assigned accessibility identifier
  (most stable).
- `--wait-text` matches accessibility id OR visible label, so it's more
  forgiving but slightly slower to evaluate.
- `--wait-text` does exact equality, not partial match. If you only have
  a substring, omit the wait flag and do one targeted `/elements` query
  after the tap.

Exit codes: `0` on success (tap + wait if specified), `1` if the tap
target wasn't found OR the wait target didn't appear in time, `2` for
WDA / usage errors.

For W3C pointer gestures `tap.rb` doesn't model (long press), see
`references/raw-actions.md`.

### Anti-pattern: rolling your own tap

```
# DON'T — 3-4 turns to tap one button.
curl -s -X POST http://localhost:8100/session/$SID/elements \
  -H 'Content-Type: application/json' \
  -d '{"using":"accessibility id","value":"create-post-button"}'
# ... extract element id ...
curl -s http://localhost:8100/session/$SID/element/$EID/rect
# ... compute center ...
curl -s -X POST http://localhost:8100/session/$SID/actions ...
curl -s 'http://localhost:8100/source?format=description'   # "check state"
```

```
# DO — 1 turn.
ruby scripts/tap.rb aid create-post-button --wait-aid post-title-field
```

## Accessibility Tree

**Always prefer the accessibility tree over screenshots.** The tree is
text-based, fast to grep, and contains everything you need (types, labels,
identifiers, coordinates).

### `format=description` — compact plaintext (default, ~25 KB)

```bash
curl -s 'http://localhost:8100/source?format=description' | jq -r .value
```

Returns a human-readable indented tree. Each line shows an element with
its type, memory address, frame as `{{x, y}, {width, height}}`, and
optional attributes (identifier, label, Selected, etc.):

```
NavigationBar, 0x105351660, {{0.0, 62.0}, {402.0, 54.0}}, identifier: 'my-site-navigation-bar'
  Button, 0x105351a20, {{16.0, 62.0}, {44.0, 44.0}}, identifier: 'BackButton', label: 'Site Name'
  StaticText, 0x105351b40, {{178.7, 73.7}, {44.7, 20.7}}, label: 'Posts'
```

**Use this format by default.** It's ~15× smaller than JSON, easy to
reason about, and contains all the navigation info you need. You can
pipe it directly to `grep` to find the few lines that matter.

For the larger `format=json` structure (when you need to walk the tree
programmatically, e.g. to read a `value` attribute by element), see
`references/json-tree.md`.

### Finding Elements

Priority order when locating something in the tree:

1. **`identifier` / `name`** — most stable; developer-assigned, unlikely
   to change across locales.
2. **`label`** — accessibility label; user-visible text, may shift with
   localization.
3. **`type` + context** — e.g. "Button inside NavigationBar".
4. **Partial matching** — element label *contains* the target text
   (useful for dynamic labels like "3 Posts").
5. **Positional heuristics** — last resort; fragile across screen sizes.

In description format, grep the tree text. Tap coordinates: from a
`{{x, y}, {w, h}}` frame the center is `(x + w/2, y + h/2)`. You almost
never need to compute this yourself, because `tap.rb` does it.

The root node's `rect` gives screen dimensions (e.g. `width: 393, height: 852`).

## Verifying step success without screenshots

When a test step ends in "verify <something is on screen>", do it through
the tree, not a screenshot. The common patterns:

**Verify a specific element is present.** Query `/elements` directly:

```bash
# Cheap presence probe (~200 B response).
SID=$(jq -r .session_id /tmp/wda-8100.session)
curl -s -X POST "http://localhost:8100/session/$SID/elements" \
  -H 'Content-Type: application/json' \
  -d '{"using":"accessibility id","value":"post-published-banner"}' \
  | jq -e '.value | length > 0'
```

**Verify a specific text is on screen.** One tree dump + grep:

```bash
curl -s 'http://localhost:8100/source?format=description' | jq -r .value \
  | grep -F "Category tag post"   # exit 0 == found
```

**Verify post-publish / save success.** Most apps surface a confirmation
toast or banner with a stable label or aid. Wait for it as part of the
tap that triggered it:

```bash
ruby scripts/tap.rb aid publish-confirm-button \
  --wait-text "Post published" --timeout 15
```

If the verification fails (text not found, exit non-zero), *then* capture
a screenshot for the human-readable failure report. Do not `Read` it
back; just write the path into the failure report.

## Swipe

**Use `scripts/swipe.rb` for every swipe.** It auto-detects the
simulator's window size, computes direction-to-coordinates from the
guide below, and dispatches the gesture in one call:

```bash
ruby scripts/swipe.rb up      # vertical swipe up (scrolls content down)
ruby scripts/swipe.rb down    # vertical swipe down (scrolls content up)
ruby scripts/swipe.rb left
ruby scripts/swipe.rb right
ruby scripts/swipe.rb back    # edge swipe from left edge → right (back nav fallback)

# Explicit coordinates if you need a custom gesture.
ruby scripts/swipe.rb at 196,500,196,200

# Slow swipe (1 s) when the gesture originates on a tappable item so it
# isn't misread as a tap.
ruby scripts/swipe.rb up --duration 1000
```

Vertical swipes use the right-edge x (`window_width - 30`) so they
don't land on interactive elements in the center. For the raw W3C
pointer-actions JSON body (e.g. multi-finger gestures or long-press
chains the script doesn't model), see `references/raw-actions.md`.

## Scroll View Navigation

To find an element in a long scrollable list:

1. Fetch the tree (description format) and grep for the target.
2. If found, `tap.rb` it. Done.
3. If not found, swipe up from the right edge to scroll down
   (`x = screen_width - 30`).
4. Re-fetch the tree and grep again.
5. **Detect end of list**: if the tree text is unchanged after a scroll,
   you've hit the bottom.
6. Stop and report element-not-found if the bottom is reached without
   finding the target.

Same pattern for horizontal scroll views with horizontal swipes.

## Type Text

**Use `scripts/type.rb` for every typing action.** It collapses
"tap-to-focus -> wait for keyboard -> send keys -> read value back"
into one call:

```bash
# Locate the field by aid (or by visible label), type the text.
# By default the script verifies the typed text landed: after typing it
# reads the field's `value` (or `label` as fallback) and exits 1 if the
# attribute doesn't contain TXT — catching dropped keys without you
# having to spend an extra tool call on a manual readback.
ruby scripts/type.rb aid post-title --text "Hello world"
ruby scripts/type.rb text "Email"   --text "user@example.com"

# Opt out of the readback if the field genuinely doesn't expose its
# typed content via value/label (rare — most do).
ruby scripts/type.rb aid post-title --text "Hello world" --no-verify

# Skip the tap + keyboard wait if the field is already focused
# (e.g. a fresh post editor that auto-focuses its title).
ruby scripts/type.rb aid post-title --text "Hello world" --no-focus
```

The script polls for `XCUIElementTypeKeyboard` to appear before sending
keys, which is the cheap focus check from the WDA API. If the keyboard
doesn't appear within `--keyboard-timeout` seconds (default 3), it
exits 1 — at which point you usually need to re-fetch the tree and tap
again at fresh coordinates. `/element/<id>/click` does not reliably
raise the keyboard for text fields; the coordinate-based tap that
`tap.rb` (and `type.rb`) does is more reliable.

The verify step checks the field's `value` attribute first, then falls
back to `label`. For most SwiftUI / UIKit text inputs the typed content
ends up in the enclosing element's `label` ("Post title. Hello world")
even when the element's own `value` is nil because the text lives on a
descendant `TextView`. Either is sufficient to catch dropped keys.

**Don't use `hasKeyboardFocus`.** That attribute is rejected on iOS 26
("attribute is unknown"); the valid name is `focused`.

**Fast typing pattern.** Use `type.rb`, then move on. Don't tree-dump
between each character or after typing. If your text is wrong on
screen, the publish/save step will surface it. Don't take a screenshot
to "see" the typed text.

For the raw `/wda/keys` curl (e.g. mixing in control codes for a
clear-field sequence) and clear-field caveats on iOS 26, see
`references/raw-actions.md`.

## Back Navigation

To return to the previous screen, find a Button inside `NavigationBar`.
Its label is typically the previous screen's title. Tap it via
`tap.rb text "<Prev Title>"` (with `--wait-aid` for the destination's
marker). For the edge-swipe fallback, see `references/raw-actions.md`.

## Screenshots

Screenshots are an output artifact for **human review only** (e.g.
attaching a failure image to a test report). Capture with `simctl`:

```bash
xcrun simctl io <UDID> screenshot /tmp/screenshot.png
```

Booted simulator UDID:

```bash
xcrun simctl list devices booted -j | jq -r '.devices | to_entries[].value[] | select(.state == "Booted") | .udid'
```

See Rule 2 above: never `Read` the resulting PNG back into context.

## Reference files

For details that you only need when something specific is happening,
read the matching reference file:

| Read this | When you need to |
|-----------|------------------|
| `references/sessions.md` | Interact with `/session/*` endpoints directly, debug "HTTP 200 but no UI effect," or understand the `bundleId` binding |
| `references/raw-actions.md` | Long-press, clear a text field (with iOS 26 caveats), or the edge-swipe back fallback |
| `references/json-tree.md` | Walk the tree programmatically with `jq` (e.g. read a `value` attribute by id) instead of grepping description format |
| `references/troubleshooting.md` | A tap silently no-ops, the app may have crashed, a system alert is intercepting input, or you need the swipe/deep-link tips |
