# Simulator Sign-In

Pass credentials as launch arguments. WordPress.com sign-in then completes automatically; the self-hosted flow still needs a couple of taps.

## WordPress.com account

The quickest path is the helper script — it launches the app with the token and, optionally, resets first:

```bash
Scripts/sim-signin.sh --wpcom-token <token>                 # Jetpack, booted simulator
Scripts/sim-signin.sh --app wordpress --wpcom-token <token> # WordPress
Scripts/sim-signin.sh --reset --wpcom-token <token>         # wipe existing state first
```

With no `--device`, the script targets the running simulator (and prompts if more than one is booted). There's also a `make` shortcut that forwards to it: `make sim-login`, with optional `DEVICE=<udid>`, `APP=wordpress`, `RESET=1`, or `ARGS="…"` for any other flags.

To set the token once and drop it from the command line, export `WPCOM_TOKEN` (e.g. in `~/.zshrc`) or write it to `~/.wpcom-token`; the script uses either when `--wpcom-token` is omitted. If none is set, it prompts you to paste one.

Or launch directly with the bearer token. The app finishes sign-in automatically while it sits on the login screen — no taps required:

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -wpcom-token <bearer-token>
```

The legacy `-ui-test-wpcom-token` argument is still accepted for backward compatibility.

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
