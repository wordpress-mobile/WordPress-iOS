---
name: ios-sim-navigation
description: Drive an iOS app running in a Simulator via WebDriverAgent (WDA) to tap, swipe, scroll, type, take screenshots, inspect the accessibility tree, automate, or verify a UI flow. Use when the work specifically targets a running Simulator app (e.g. running an end-to-end test, automating an in-app flow, verifying on-screen state via the WDA tree, scripting taps in a simulator). Do not use for non-Simulator UI work, headless code paths, or UI tasks on real devices.
---

# iOS Simulator Navigation with WebDriverAgent

Drive an explicitly identified app on a user-identified Simulator through one
explicitly identified WDA session.

## Required navigation target

Retain these values in working context throughout the flow:

- `<UDID>`: resolve the Simulator identified by the user or established earlier
  in the task to its exact UDID. If the target cannot be determined
  unambiguously, ask the user which Simulator to use.
- `<BUNDLE_ID>`: use the bundle ID established earlier in the task, or resolve it
  from the app explicitly identified by the user. If the target app cannot be
  determined unambiguously, ask the user which app to use. Never choose an app
  merely because it is installed, running, or in the foreground.
- `<PORT>`: choose a random port from 8200 through 8999. If unavailable,
  choose another and retry.
- `<SESSION_ID>`: the exact value printed by `wda-session.rb`.

Pass `<PORT>` and `<SESSION_ID>` explicitly to every WDA action. Keep using the
resolved `<UDID>` and `<BUNDLE_ID>` throughout the flow.

## Fast-path cadence

End-to-end runs have a limited time budget. Keep each user-visible action to
about one tool call.

### Rule 1: Use `tap.rb` for every tap

`tap.rb` validates the supplied session, finds the element, computes its
coordinates, taps it, and can wait for the next screen in one invocation:

```bash
ruby scripts/tap.rb aid create-post-button \
  --port <PORT> --session-id <SESSION_ID> \
  --wait-aid post-title-field
```

Use raw curl only for gestures that the scripts do not model.

### Rule 2: Never read a screenshot into model context

Use the accessibility tree to make decisions. Screenshots are failure artifacts
for human review only. Never read `/tmp/*.png` back into context.

### Rule 3: Fetch one tree per screen

Fetch the description tree once on a new screen, locate the controls you need,
then use the action scripts. Re-fetch only after reaching another screen or
when an expected transition times out.

```bash
curl -s "http://localhost:<PORT>/session/<SESSION_ID>/source?format=description" \
  | jq -r .value
```

## Before starting WDA

Verify that:

- `<UDID>` identifies a booted Simulator.
- The app identified by `<BUNDLE_ID>` is installed on that Simulator.

## WDA lifecycle

Run `wda-start.rb` with both required options:

```bash
ruby scripts/wda-start.rb --udid <UDID> --port <PORT>
```

Run that command using the coding environment's tracked background-command
facility. Retain the returned task or terminal identifier. Do not append `&`,
use `nohup`, or detach it another way.

Startup may take several minutes on first use. Poll the selected port until WDA
is ready:

```bash
curl -sf "http://localhost:<PORT>/status" >/dev/null
```

The script handles setup and one recovery attempt internally. If startup
reports that the port is occupied, choose another random port from 8200 through
8999 and retry. If the background task exits for another reason, inspect its
output and report the failure. Do not restart it automatically.

When navigation finishes, stop the exact background task using its retained
identifier. Do not scan for WDA processes or stop unrelated background tasks.
No additional cleanup command is required.

## Create the app session

Create a session before every navigation flow. Both options are required:

```bash
ruby scripts/wda-session.rb --port <PORT> --bundle <BUNDLE_ID>
```

The command prints only the session ID to stdout. Retain that exact value as
`<SESSION_ID>` and pass it to every subsequent action.

Creating the session launches or relaunches the app and binds WDA to it. Do not
substitute `simctl launch`, because a later WDA session can relaunch the app and
discard caller-supplied launch configuration.

For launch arguments or environment variables, add repeatable options to the
same session command:

```bash
ruby scripts/wda-session.rb --port <PORT> --bundle <BUNDLE_ID> \
  --arg -some-flag --arg value

ruby scripts/wda-session.rb --port <PORT> --bundle <BUNDLE_ID> \
  --env SOME_INSTRUMENT_VAR=1
```

`--wait-quiescence` is off by default because a spinner can prevent an app from
becoming quiescent. If a session becomes invalid, create a new session
explicitly and use its new ID. Action scripts never replace sessions silently.

See `references/sessions.md` for session details.

## Tap

Use one of three locators:

```bash
# Developer-assigned accessibility identifier (preferred).
ruby scripts/tap.rb aid settings-button \
  --port <PORT> --session-id <SESSION_ID>

# Visible label or accessibility identifier.
ruby scripts/tap.rb text "Continue" \
  --port <PORT> --session-id <SESSION_ID>

# Coordinates, only when no stable identifier or label exists.
ruby scripts/tap.rb at 196,504 \
  --port <PORT> --session-id <SESSION_ID>
```

### Fuse tap and transition verification

Use `--wait-aid` or `--wait-text` whenever you can name an element expected on
the destination screen:

```bash
ruby scripts/tap.rb aid tabbar_mysites \
  --port <PORT> --session-id <SESSION_ID> \
  --wait-aid switch-site-button

ruby scripts/tap.rb text "Continue" \
  --port <PORT> --session-id <SESSION_ID> \
  --wait-text "My Site"

ruby scripts/tap.rb aid publish-button \
  --port <PORT> --session-id <SESSION_ID> \
  --wait-text "Post published" --timeout 15
```

The wait polls `/elements` every 250 ms. `--wait-aid` uses the stable
accessibility identifier. `--wait-text` uses exact equality against label or
identifier.

Exit codes:

- `0`: tap and optional wait succeeded.
- `1`: target missing or wait timed out.
- `2`: invalid options, WDA unavailable, or session invalid.

## Accessibility tree

Use description format by default:

```bash
curl -s "http://localhost:<PORT>/session/<SESSION_ID>/source?format=description" \
  | jq -r .value
```

Each line contains type, frame, identifier, label, and other useful state. Find
elements in this order:

1. Developer-assigned `identifier` or `name`.
2. Accessibility `label`.
3. Type plus surrounding context.
4. Partial text matching.
5. Position, only as a last resort.

For programmatic tree walking, read `references/json-tree.md`.

## Verify step success

Verify presence through the explicit session:

```bash
curl -s -X POST \
  "http://localhost:<PORT>/session/<SESSION_ID>/elements" \
  -H 'Content-Type: application/json' \
  -d '{"using":"accessibility id","value":"post-published-banner"}' \
  | jq -e '.value | length > 0'
```

Verify visible text with one tree dump:

```bash
curl -s "http://localhost:<PORT>/session/<SESSION_ID>/source?format=description" \
  | jq -r .value \
  | grep -F "Category tag post"
```

Prefer adding a wait to the tap that triggers a confirmation. Capture a
screenshot only after verification fails, and do not read the image back.

## Swipe

Use `swipe.rb` for every swipe:

```bash
ruby scripts/swipe.rb up --port <PORT> --session-id <SESSION_ID>
ruby scripts/swipe.rb down --port <PORT> --session-id <SESSION_ID>
ruby scripts/swipe.rb left --port <PORT> --session-id <SESSION_ID>
ruby scripts/swipe.rb right --port <PORT> --session-id <SESSION_ID>
ruby scripts/swipe.rb back --port <PORT> --session-id <SESSION_ID>

ruby scripts/swipe.rb at 196,500,196,200 \
  --port <PORT> --session-id <SESSION_ID>

ruby scripts/swipe.rb up \
  --port <PORT> --session-id <SESSION_ID> --duration 1000
```

Directional swipes derive coordinates from the session's window size. Vertical
swipes use the right edge to avoid interactive controls in the center.

## Scroll view navigation

1. Fetch the tree and look for the target.
2. Tap it if found.
3. Otherwise swipe up and fetch the tree again.
4. Stop when the tree is unchanged after a swipe, which indicates the end.
5. Report element-not-found if the target never appears.

## Type text

Use `type.rb` for every typing action. It finds the field, taps it, waits for
the keyboard, types, and verifies the exposed value or label:

```bash
ruby scripts/type.rb aid post-title --text "Hello world" \
  --port <PORT> --session-id <SESSION_ID>

ruby scripts/type.rb text "Email" --text "user@example.com" \
  --port <PORT> --session-id <SESSION_ID>
```

Use `--no-verify` only when the field genuinely does not expose typed text. Use
`--no-focus` when the field is already focused:

```bash
ruby scripts/type.rb aid post-title --text "Hello world" \
  --port <PORT> --session-id <SESSION_ID> --no-focus
```

Do not use `hasKeyboardFocus`; iOS 26 rejects it. The valid attribute is
`focused`. Do not tree-dump between characters or after successful verification.

See `references/raw-actions.md` for control-code typing and clear-field details.

## Back navigation

Find the Button inside the NavigationBar and tap its label. If no stable button
exists, use the `back` swipe:

```bash
ruby scripts/swipe.rb back --port <PORT> --session-id <SESSION_ID>
```

## Screenshots

Screenshots are failure artifacts for human review only. Use the resolved UDID:

```bash
xcrun simctl io <UDID> screenshot /tmp/screenshot.png
```

Do not re-resolve or switch the screenshot target after `<UDID>` is established,
and never read the resulting PNG into model context.

## Reference files

| Read this | When you need to |
|-----------|------------------|
| `references/sessions.md` | Understand explicit session creation, relaunch behavior, or invalid sessions |
| `references/raw-actions.md` | Perform long press, clear a field, send control codes, or build a custom gesture |
| `references/json-tree.md` | Walk the JSON tree programmatically |
| `references/troubleshooting.md` | Diagnose no-op actions, crashes, alerts, or WDA disconnections |
