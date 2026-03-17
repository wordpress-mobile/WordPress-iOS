# Simulator Sign-In

Launch the app with credentials to enable automatic sign-in on the simulator.

## Step 1: Providing Credentials

### Self-hosted site

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-reset-everything \
  -ui-test-site-url https://example.com \
  -ui-test-site-user <username> \
  -ui-test-site-pass <application-password>
```

### WordPress.com account

```bash
xcrun simctl launch --terminate-running-process booted org.wordpress \
  -ui-test-reset-everything \
  -ui-test-wpcom-token <bearer-token>
```

## Step 2: Signing In

After launching with credentials, the app displays a sign-in page with two buttons: **"Continue with WordPress.com"** and **"Enter your existing site address"**.

### WordPress.com account

Tap **"Continue with WordPress.com"**. You will be automatically signed in.

### Self-hosted site

1. Tap **"Enter your existing site address"**
2. Enter the site address in the text field
3. Tap **"Continue"**

You will be automatically signed in.
