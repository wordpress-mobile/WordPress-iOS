# Simulator Sign-In

Pass credentials as launch arguments, then tap through the sign-in screen to complete sign-in.

## WordPress.com account

Launch with a bearer token:

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-wpcom-token <bearer-token>
```

On the sign-in screen, tap **"Continue with WordPress.com"**.

## From a signed-in device (Session Transfer)

Copy a WordPress.com session from a device that's already signed in — handy for the Simulator, which can't easily run the web sign-in flow, and needs no bearer token on hand. Debug/internal builds only. Both devices must be on the same Wi-Fi and running the same app and configuration (e.g. Jetpack debug on both, so their `jpdebug://` URL schemes match).

On the **Simulator** (the receiver):

1. Open the debug menu — swipe in from the right edge (or **Me ▸ App Settings ▸ Debug**).
2. Tap **Session Transfer ▸ Receive Session**. It starts listening and shows an address, a key fingerprint, and a QR code. The address is the *Mac's* LAN address — the Simulator shares the host's network stack, so a physical device on the same Wi-Fi can reach the listener. The session is encrypted to a per-session public key advertised in the QR and Bonjour record, so the bearer token is never readable in flight.

On the **signed-in device** (the sender):

3. Scan the QR code with the Camera app and open the link in the app.
4. Confirm the **Send WordPress.com Session?** prompt. The app POSTs the session to the Simulator, which signs in.

Only local-network destinations are accepted, so a session can't be sent to a public host. Keep the Receive Session screen in the foreground while pairing.

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
