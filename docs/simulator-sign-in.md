# Simulator Sign-In

Pass credentials as launch arguments. WordPress.com sign-in then completes automatically; the self-hosted flow still needs a couple of taps.

## WordPress.com account

The quickest path is **`make sim-login`** — it signs the running simulator into WordPress.com, prompting you to choose when more than one simulator is booted, and to paste a token if none is configured:

```bash
make sim-login                # sign the running simulator into Jetpack
make sim-login APP=wordpress  # WordPress instead of Jetpack
make sim-login RESET=1        # wipe existing app state first
make sim-login DEVICE=<udid>  # target a specific simulator
```

`make sim-login` forwards to `Scripts/sim-signin.sh`, which you can run directly with the same options as flags — `--app`, `--device`, `--reset`, `--wpcom-token` (or pass `ARGS="…"` through `make` for any flag without a dedicated variable):

```bash
Scripts/sim-signin.sh --app wordpress --reset
```

The token is resolved from `--wpcom-token`, then `WPCOM_TOKEN`, then `~/.wpcom-token`; if none is set it prompts you to paste one and offers to save it to `~/.wpcom-token` for next time. Set it once — export `WPCOM_TOKEN` in `~/.zshrc`, or write `~/.wpcom-token` — to skip the token entirely.

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
