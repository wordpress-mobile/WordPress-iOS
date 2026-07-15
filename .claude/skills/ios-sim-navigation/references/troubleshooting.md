# Troubleshooting

## Session is invalid

Action scripts validate the supplied session before sending input. If a script
reports that the session is not active, create a new one explicitly:

```bash
ruby scripts/wda-session.rb --port <PORT> --bundle <BUNDLE_ID>
```

Use the newly printed session ID for every later command. Never retry with an
ID from another port or session.

## Element coordinates became stale

Elements move during animations, keyboard transitions, and list updates. Use
`tap.rb` or `type.rb` so the element is located and its frame is read within the
same invocation. Re-fetch the tree only when the helper cannot find the target.

## A system alert intercepts input

Query the alert through the explicit session:

```bash
curl -s \
  "http://localhost:<PORT>/session/<SESSION_ID>/alert/text" \
  | jq -r .value
```

If the alert buttons appear in the accessibility tree, tap the desired button
with `tap.rb text`. Do not guess coordinates over an alert.

## App crashed or returned to SpringBoard

Inspect the active application on the selected port:

```bash
curl -s "http://localhost:<PORT>/wda/activeAppInfo" | jq .value
```

If the app is no longer active, create a new session with its bundle ID. A new
session relaunches the app and yields a new session ID.

## WDA disconnected

Inspect the retained background task. If it exited, read its output for the
`xcodebuild` failure. Start a new tracked background task with the same supplied
UDID and a newly chosen random port, then create a new app session.

Do not scan for WDA processes or stop background tasks that this flow did not
start.

## Deep links

When the app supports a useful deep link, open it only on the caller-supplied
Simulator:

```bash
xcrun simctl openurl <UDID> <URL>
```

Create a new WDA session afterward if the current session no longer dispatches
input.
