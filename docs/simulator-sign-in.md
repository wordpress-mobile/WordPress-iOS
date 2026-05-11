# Simulator Sign-In

Launch the app with credentials to enable automatic sign-in on the simulator.

## Step 1: Providing Credentials

### Self-hosted site

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-site-url https://example.com \
  -ui-test-site-user <username> \
  -ui-test-site-pass <application-password>
```

### WordPress.com account

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-wpcom-token <bearer-token>
```

If the app has lingering state from a previous run, reset it in a separate
command before the sign-in launch — see [Launch Arguments](#launch-arguments).

## Step 2: Signing In

After launching with credentials, the app displays a sign-in page with two buttons: **"Continue with WordPress.com"** and **"Enter your existing site address"**.

### WordPress.com account

Tap **"Continue with WordPress.com"**. You will be automatically signed in.

### Self-hosted site

1. Tap **"Enter your existing site address"**
2. Enter the site address in the text field
3. Tap **"Continue"**

You will be automatically signed in.

## Launch Arguments

- `-ui-test-reset-everything` — wipes the Core Data store and `UserDefaults`
  on launch. Skip it when the simulator is already fresh (e.g. just after
  `xcrun simctl erase`).

  Don't combine it with the sign-in arguments in one command. Run it on its
  own, then relaunch with the credentials:

  ```bash
  xcrun simctl launch --terminate-running-process booted org.wordpress \
    -ui-test-reset-everything
  xcrun simctl launch --terminate-running-process booted org.wordpress \
    -ui-test-site-url https://example.com \
    -ui-test-site-user <username> \
    -ui-test-site-pass <application-password>
  ```
