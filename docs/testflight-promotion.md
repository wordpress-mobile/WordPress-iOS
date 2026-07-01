# TestFlight Promotion

Every trunk push uploads WordPress and Jetpack to the **internal** TestFlight group (`build_and_upload_app_for_testflight` in `fastlane/lanes/build.rb`). This covers promoting those builds onward through two more beta tiers:

```
per-commit  →  internal TestFlight
daily 00:00 →  last build of the day  →  Nightly Beta Testers   (automatic)
weekly      →  a developer picks a nightly  →  public beta        (human-chosen)
```

Each promotion is a metadata-only App Store Connect call that adds an existing build to an external group — no rebuild.

## Daily: last build of the day → nightly

`promote_nightly_build` (via `.buildkite/promote-nightly.yml`) finds the newest processed build uploaded in the last `NIGHTLY_LOOKBACK_HOURS` and distributes it to the **Nightly Beta Testers** group for both apps. Fully automatic; a quiet day (no new builds) is a no-op.

## Weekly: a nightly → public beta

`.buildkite/promote-testflight.yml` runs three steps:

1. **Gather** (`gather_testflight_candidates`) lists the `VALID` builds in the **Nightly Beta Testers** group, scoped to the highest marketing version and the last `PROMOTION_MAX_AGE_DAYS` days, newest first. It uploads a **block step** with those builds as a dropdown and posts the list to `#build-and-ship`.
2. **Choose** — the Slack message links to the block step's unblock dialog, where a developer picks a build.
3. **Promote** (`promote_build`) distributes the chosen build to the public beta group for both apps.

Both apps share a build code, so one selection promotes both.

## Safety

Every lane refuses to run anywhere but **`trunk`** — including the weekly `gather_testflight_candidates`, which bails before it reads App Store Connect or opens a picker. Run from any other branch, or locally, they fail immediately — an off-trunk promotion is a mistake. The schedules only run on `trunk` regardless, so the guard is a backstop against a stray manual run.

## Buildkite setup

The pipeline files live in the repo; the schedules that run them are managed in Terraform as `buildkite_pipeline_schedule` resources on the existing `wordpress-ios` pipeline. The trampoline uploads `.buildkite/${PIPELINE:-pipeline.yml}`, so a schedule selects its file with `env = { PIPELINE = "promote-nightly.yml" }`.

- **Nightly** — cron `0 0 * * *`, branch `trunk`.
- **Public** — cron `0 14 * * 5` (Fridays 14:00 UTC), branch `trunk`. The cron is the cadence knob.

No new secrets or queues — the steps reuse the existing App Store Connect API key, Slack webhook, and Buildkite token, and run on the `mac` queue.

## Configuration

All constants are in `fastlane/lanes/promote.rb`:

| What | Where |
| --- | --- |
| Cadence | the Buildkite schedules (cron) |
| Candidates shown | `PROMOTION_CANDIDATE_LIMIT` |
| Recency window (days) | `PROMOTION_MAX_AGE_DAYS` |
| Nightly lookback (hours) | `NIGHTLY_LOOKBACK_HOURS` |
| Beta group names | `NIGHTLY_BETA_GROUP_NAME`, `WORDPRESS_PUBLIC_BETA_GROUPS`, `JETPACK_PUBLIC_BETA_GROUPS` |

## Manual promotion

These lanes only run on `trunk`, so a manual promotion means triggering the relevant Buildkite pipeline on `trunk` (set `PIPELINE=promote-nightly.yml` or `PIPELINE=promote-testflight.yml` — see [Buildkite setup](#buildkite-setup)), not running fastlane locally. A local invocation refuses to run, by design.

## Caveats

- The weekly list reads the **Nightly Beta Testers** group, so it's empty until the daily job has populated it on `trunk`. Both apps must have that group in App Store Connect.
- **Reader** isn't promoted — excluded from the internal build matrix while its App Store archive is broken (#25321).
- An un-actioned weekly promotion stays blocked in Buildkite until cancelled; the next week's build doesn't clear it.
- The nightly job promotes the newest **`VALID`** build in the lookback window, so a build still *processing* when the job runs is skipped — and won't be picked up later either (the next run only looks back `NIGHTLY_LOOKBACK_HOURS`). The `0 0 * * *` schedule makes this rare (the last build is usually hours old), but a commit landing minutes before the run can miss that night's promotion.
- The nightly job picks that build by upload time alone — it doesn't filter by branch or marketing version. While a release is in flight, `release/*` builds (a different `VERSION_SHORT`, distributed straight to public beta) land in the same App Store Connect app, so a release build that happens to be the most recent upload when the job runs could be promoted to nightly instead of the latest `trunk` build. Left unguarded by choice: the job only runs on `trunk`, a per-commit `trunk` build is normally the newest upload, and a release branch's version is out of step with `trunk` only briefly (it's merged back soon after the version bump) — so the window is short. The weekly public promotion is human-picked, so a stray nightly build wouldn't silently reach public beta.
- A promotion runs **per app** — WordPress and Jetpack are distributed independently (`distribute_build_to_apps`). If one succeeds and the other fails (a renamed beta group, a transient App Store Connect error), the lane reports the per-app result to Slack and exits non-zero, but the app that already succeeded **stays distributed** — there's no rollback. The two can sit a cycle apart until the next run reconciles them: the nightly job re-promotes the newest build automatically; the weekly promotion is re-triggered by hand. Re-promotion is idempotent — an already-distributed build isn't re-submitted for review or re-notified — so re-running after a partial failure is safe.
