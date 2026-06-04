# WDA Session Management

Most action endpoints (`/element/...`, `/elements`, `/wda/keys`, `/actions`)
require a session id. `tap.rb` manages this for you automatically — it
creates a session bound to the foreground app's bundle id, persists it at
`/tmp/wda-<port>.session`, and reuses it across calls. **Read this only
when interacting with `/session/...` endpoints directly.**

## Why the bundleId binding matters

Without `bundleId` in the session's capabilities, `/actions` returns
HTTP 200 but the taps never reach the UI: a silent failure that's easy
to mistake for "WDA is broken." Read the active bundle from
`/wda/activeAppInfo` and include it in `alwaysMatch`:

```bash
BUNDLE=$(curl -s http://localhost:8100/wda/activeAppInfo | jq -r .value.bundleId)
SID=$(curl -s -X POST http://localhost:8100/session \
  -H 'Content-Type: application/json' \
  -d "{\"capabilities\":{\"alwaysMatch\":{\"bundleId\":\"$BUNDLE\"}}}" \
  | jq -r .value.sessionId)
echo "$SID"
```

## Reusing the session `tap.rb` persists

For non-tap curl calls (e.g. `/actions` swipes, `/wda/keys`), reuse the
session id that `tap.rb` already established:

```bash
SID=$(jq -r .session_id /tmp/wda-8100.session)
```

Don't mint a fresh session with `alwaysMatch:{}` for these calls — that
produces an unbound session whose `/actions` requests return HTTP 200
but never reach the UI.

## Launching with arguments: use `wda-session.rb`, not `simctl`

Creating a session relaunches the target app even when it's already running
(`forceAppLaunch` defaults to `YES`), so any arguments passed via
`simctl launch -key value` are lost — they belong to the original process, and
the relaunch starts a new one.

So when the app needs launch arguments, don't pass them with `simctl`. Let WDA
launch the app with them in the call that creates the session, using
`scripts/wda-session.rb`. It persists the session so `tap.rb` reuses it (no
further relaunch):

```bash
ruby scripts/wda-session.rb --bundle com.example.app \
  --arg -some-flag --arg value
```

Once that session exists, avoid forcing another relaunch before the arguments
are consumed (don't `simctl launch` again, don't delete the session file).
`--wait-quiescence` is off by default because a screen with a spinner can keep
the app from going quiescent and stall the call.

## When sessions break

If the foreground app changes (you launch a different bundle, or iOS
pushes you to Springboard), the existing session may stop dispatching
events. Recreate it with the new bundle id, or just call any `tap.rb`
command (it auto-rebinds).

Symptoms of a dead session: action requests return HTTP 4xx, or (more
confusingly) return HTTP 200 with no visible UI effect. `tap.rb`
recreates the session automatically on the next call.
