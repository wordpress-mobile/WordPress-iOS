# WDA Session Management

Every session is created explicitly and passed directly to each navigation
command. No script reads or writes a session file.

## Create a bound session

WDA pointer events require a session bound to the app bundle ID. Create it with
the selected port and bundle ID:

```bash
ruby scripts/wda-session.rb --port <PORT> --bundle com.example.app
```

The command prints only the session ID. Retain that value and pass it to every
tap, type, swipe, tree, alert, and raw-action request.

Do not create a session with an empty `alwaysMatch` object. Such a session can
return HTTP 200 for pointer actions without delivering them to the app.

## Launch with arguments or environment

Creating a session relaunches the target app by default. Arguments or
environment passed through `simctl launch` therefore do not survive session
creation. Put them on the session itself:

```bash
ruby scripts/wda-session.rb --port <PORT> --bundle com.example.app \
  --arg -some-flag --arg value

ruby scripts/wda-session.rb --port <PORT> --bundle com.example.app \
  --env MallocStackLogging=1 --env SOME_FLAG=on
```

Each `--arg` contributes one ordered launch-argument token. Each `--env`
contributes one `KEY=VALUE` entry. `--wait-quiescence` is off by default because
a spinner can prevent the app from becoming quiescent.

Once the session exists, do not relaunch the app through `simctl` before using
it. Create a fresh WDA session instead when a clean app launch is required.

## Use the session directly

All WDA calls use the selected port and printed session ID:

```bash
curl -s \
  "http://localhost:<PORT>/session/<SESSION_ID>/source?format=description" \
  | jq -r .value
```

Action scripts validate `GET /session/<SESSION_ID>` before dispatching input.
If validation fails, create a new session explicitly and replace the session ID
in subsequent commands. Scripts never infer a bundle or recreate a session.

## Invalid sessions

A session can become invalid when:

- The app is relaunched outside the session.
- Another session replaces it.
- WDA exits or restarts.
- The app crashes or iOS returns to SpringBoard.

Treat an invalid session as a hard boundary. Create a new one with
`wda-session.rb`; do not retry the action with a guessed or persisted ID.
