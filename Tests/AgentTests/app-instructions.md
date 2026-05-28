## Login

This app uses a self-hosted WordPress site login flow. The app password is
passed via launch arguments — NEVER type a password manually.

- NEVER tap "Continue with WordPress.com", NEVER enter WordPress.com
  email/password, and NEVER request a login link.
- Tap "Enter your existing site address", then enter the site host first
  (without scheme, for example `example.com`). If the app rejects the
  host-only form, try the full site URL once.
- If you reach any WordPress.com email/password screen, back out and
  return to the self-hosted flow.
- If the app is already logged in (e.g., My Site tab visible), skip login.
