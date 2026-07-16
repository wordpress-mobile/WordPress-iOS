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

Copy a WordPress.com session from a device that's already signed in — handy for the Simulator, which can't easily run the web sign-in flow, and needs no bearer token on hand. Debug/internal builds only. Both devices must be on the same Wi-Fi and running the same app and configuration (e.g. Jetpack debug on both).

On the **Simulator** (the receiver): just launch the app and leave it on the login screen. While it's signed out and in the foreground it automatically advertises for a session over Bonjour — there's nothing to tap. (In the Simulator the listener lives on the host Mac, so a physical device on the same Wi-Fi can reach it via the Mac's LAN address.)

On the **signed-in device** (the sender), either:

- Open **Me ▸ App Settings ▸ Debug ▸ Session Transfer ▸ Send Session** and tap the Simulator in the list; or
- Turn on **Session Transfer ▸ Offer to log in nearby devices** and tap **Continue** on the prompt when it appears. The app watches for nearby devices asking to sign in while it's in the foreground.

Either way the Simulator then shows a **QR code** and the sender opens the camera — point it at the QR to finish. The session is sealed to the key in that QR, which the receiver only ever shows on its screen (never over the network), so the token is unreadable in flight and can't be captured by an impostor advertising a fake receiver on the same Wi-Fi. The Simulator signs in and lands on the app.

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
