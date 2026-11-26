# Simulator Sign-In

Pass credentials as launch arguments. WordPress.com sign-in then finishes on its own; a self-hosted site still needs a few taps.

## WordPress.com account

Launch with a bearer token. Read it from a file inside the command, so the token never appears in the command you type, your shell history or an agent's transcript:

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -wpcom-token "$(cat <path-to-token-file>)"
```

The app signs in as soon as the sign-in screen appears. It does this once per launch, so signing out leaves you on the sign-in screen.

Agents: don't print the token file or paste the token into a command. The token still shows in `ps` while `simctl launch` runs, as any launch argument does.

The older `-ui-test-wpcom-token` argument still works.

## Self-hosted site

Launch with the site URL, a username, and an application password:

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-site-url https://example.com \
  -ui-test-site-user <username> \
  -ui-test-site-pass <application-password>
```

On the sign-in screen:

1. Tap **"Enter your existing site address"**.
2. Type the site address.
3. Tap **"Continue"**.

## Resetting state

If the app has state from a previous run, wipe the Core Data store and `UserDefaults` before signing in. Skip this on a fresh simulator (e.g. just after `xcrun simctl erase`).

Run the reset on its own — don't combine it with the credential arguments — then relaunch with the sign-in arguments above:

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-reset-everything
```
