# Troubleshooting and Tips

## Common Failures

### WDA session expiry

WDA sessions can expire after inactivity, or stop dispatching events
when the foreground app changes. Symptoms: action requests return HTTP
4xx, or (more confusingly) return HTTP 200 with no visible UI effect
(see `references/sessions.md` for the bundleId gotcha). `tap.rb`
recreates the session automatically on the next call. For direct curl
work, recreate it bound to the current foreground app using the snippet
in `references/sessions.md`.

### Stale element coordinates

After animations or screen transitions, previously fetched coordinates
may be wrong. `tap.rb` always re-resolves the element by aid/text before
tapping, so prefer it over caching coordinates yourself.

### System alert interception

System alerts (location permissions, notification permissions, tracking
prompts) can block interactions with the app. If a tap silently does
nothing:

1. Fetch the tree and look for elements of type `Alert` or `Sheet`.
2. If found, look for a dismiss button ("Allow", "Don't Allow", "OK",
   "Cancel") and tap it with `tap.rb text "<button>"`.
3. Retry the original action.

### App crash detection

If actions consistently fail or the tree looks unexpected, the app may
have crashed. Check and re-launch:

```bash
xcrun simctl list devices booted
xcrun simctl launch <UDID> <APP_BUNDLE_ID>
```

After re-launching, the next `tap.rb` call will create a fresh session
automatically.

## Tips

- **Tree coordinates, not screenshot pixels** — screenshots may be at a
  different resolution than the tree's point-based coordinates.
- **Vertical swipes**: right-edge x (`screen_width - 30`) avoids
  accidentally tapping interactive elements in the center.
- **Slow swipes on tappable items**: gestures may register as a tap.
  Use `duration: 1000` (1 s) for reliability.
- **WDA startup time**: minutes on a cold checkout (the build phase
  runs first); ~60 s once DerivedData is warm.
- **Reconnecting**: if WDA disconnects, re-run `wda-start.rb`.
- **Tab bar**: look for elements with type containing `TabBar`. Its
  children are the individual tabs.
- **Deep links for navigation**: when the target app supports URL
  schemes, `xcrun simctl openurl <UDID> <url>` (e.g.
  `wordpress://post/new`) jumps straight to a screen and skips
  multi-tap navigation chains. Both faster and less flaky than driving
  the UI to get there.
