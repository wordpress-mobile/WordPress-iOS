# Simulator Sign-In

Pass credentials as launch arguments, then tap through the sign-in screen to complete sign-in.

## WordPress.com account

Launch with a bearer token:

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-wpcom-token <bearer-token>
```

On the sign-in screen, tap **"Continue with WordPress.com"**.

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
