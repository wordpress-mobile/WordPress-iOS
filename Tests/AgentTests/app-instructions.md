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

## REST API Boundaries

- REST phases are ordered: setup, verification, then cleanup. Never return to
  an earlier phase after a later phase has started.
- During setup, use REST mutations only to prepare fixtures before the UI
  depends on them. Never use setup to perform, repair, or finish the app UI
  action under test.
- Verification is read-only and may use only GET requests. Cleanup may use GET
  and DELETE to remove resources created by the test. Batch requests follow the
  same phase restrictions.
- If the app displays an error while performing a required UI action, record
  the failure, perform any safe cleanup, and call `complete_test` with
  `status=fail`.
