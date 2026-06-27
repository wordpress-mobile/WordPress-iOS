# frozen_string_literal: true

require 'spaceship'
require 'time'

# Promotes an already-uploaded TestFlight build through the beta tiers without
# rebuilding — each promotion is a metadata-only App Store Connect call. This
# adds the daily nightly tier on top of the per-commit internal build (build.rb):
#
#   per-commit  → internal TestFlight
#   daily 00:00 → `promote_nightly_build`: last build of the day → nightly group
#
# WordPress and Jetpack share a build code (same CI run), so one build promotes both.

NIGHTLY_LOOKBACK_HOURS = 24

# External nightly beta group. Both apps use the same group name.
NIGHTLY_BETA_GROUP_NAME = 'Nightly Beta Testers'
WORDPRESS_NIGHTLY_BETA_GROUPS = [NIGHTLY_BETA_GROUP_NAME].freeze
JETPACK_NIGHTLY_BETA_GROUPS = [NIGHTLY_BETA_GROUP_NAME].freeze

platform :ios do
  # Promotes the last processed build of the day to the nightly group for both
  # apps. Automatic on a daily schedule; the weekly promotion picks from this group.
  #
  # @called_by CI (`.buildkite/commands/promote-nightly.sh`)
  desc 'Promote the last build of the day to the nightly beta group (WordPress + Jetpack)'
  lane :promote_nightly_build do |dry_run: nil|
    dry_run = dry_run_for(dry_run)
    log_prefix = dry_run ? '[dry run] ' : ''

    build = latest_build_of_the_day
    if build.nil?
      UI.important("#{log_prefix}No build uploaded in the last #{NIGHTLY_LOOKBACK_HOURS}h; nothing to promote to nightly.")
      next
    end

    build_code = build.version
    # Use the build's authoritative marketing version; only promote_build (which gets a
    # bare build code with no build object) needs the marketing_version_from_build_code heuristic.
    app_version = build.pre_release_version&.version
    UI.important("#{log_prefix}Promoting last build of the day #{build_code} (version #{app_version}) to nightly beta for WordPress and Jetpack")

    results = distribute_build_to_apps(
      build_code: build_code,
      app_version: app_version,
      app_groups: nightly_beta_app_groups,
      changelog: nightly_changelog(build_code: build_code),
      dry_run: dry_run
    )

    post_promotion_result_to_slack(build_code: build_code, app_version: app_version, results: results, dry_run: dry_run, tier: 'nightly')

    failed = results.select { |_, result| result[:ok] == false }.keys
    UI.user_error!("Nightly promotion failed for: #{failed.join(', ')}") unless failed.empty?

    UI.success("#{log_prefix}Promoted #{build_code} to nightly for: #{results.keys.join(', ')}")
  end
end

#################################################
# Helper Functions
#################################################

# Distributes a build to each app's groups, returning a per-app `{ ok:, error: }`
# result. A failure for one app doesn't stop the other.
def distribute_build_to_apps(build_code:, app_version:, app_groups:, changelog:, dry_run:)
  app_groups.to_h do |app|
    result =
      begin
        promote_existing_build_to_groups(app: app, app_version: app_version, build_code: build_code, changelog: changelog, dry_run: dry_run)
        { ok: true }
      rescue StandardError => e
        UI.error("Failed to promote #{app[:name]} (#{build_code}): #{e.message}")
        { ok: false, error: e.message }
      end
    [app[:name], result]
  end
end

def nightly_beta_app_groups
  [
    { name: 'WordPress', identifier: WORDPRESS_BUNDLE_IDENTIFIER, groups: WORDPRESS_NIGHTLY_BETA_GROUPS },
    { name: 'Jetpack', identifier: JETPACK_BUNDLE_IDENTIFIER, groups: JETPACK_NIGHTLY_BETA_GROUPS }
  ]
end

# `distribute_only: true` locates the existing build (by marketing version + build
# code) and adds it to the named external groups for beta review — no new binary.
def promote_existing_build_to_groups(app:, app_version:, build_code:, changelog:, dry_run: false)
  if dry_run
    UI.important("[dry run] Would distribute #{build_code} (#{app_version}) to #{app[:groups].join(', ')} for #{app[:identifier]} — skipping App Store Connect.")
    return
  end

  # pilot silently skips any group name it can't match, so a renamed/typo'd group
  # would "succeed" while adding the build to zero testers. Fail loudly instead.
  verify_beta_groups_exist!(app_identifier: app[:identifier], group_names: app[:groups])

  upload_to_testflight(
    api_key: app_store_connect_api_key,
    team_id: get_required_env('FASTLANE_ITC_TEAM_ID'),
    app_identifier: app[:identifier],
    app_platform: 'ios',
    app_version: app_version,
    build_number: build_code,
    distribute_only: true,
    distribute_external: true,
    notify_external_testers: true,
    submit_beta_review: true,
    groups: app[:groups],
    changelog: changelog,
    # Don't disrupt a submission already in review.
    reject_build_waiting_for_review: false
  )
end

# Confirms every named group exists for the app before we hand it to pilot, which
# would otherwise drop unknown group names without error (reporting success while
# distributing to no one). Raises so the per-app result is recorded as a failure.
def verify_beta_groups_exist!(app_identifier:, group_names:)
  existing = app_store_connect_app(app_identifier).get_beta_groups.map(&:name)
  missing = group_names - existing
  return if missing.empty?

  UI.user_error!("Beta group(s) #{missing.join(', ')} not found for #{app_identifier} in App Store Connect (found: #{existing.join(', ')})")
end

# Build codes are `<major>.<minor>.0.<buildkite-number>`; the marketing version is the first two parts.
def marketing_version_from_build_code(build_code)
  build_code.split('.').first(2).join('.')
end

def real_promotion_run?
  ENV.fetch('BUILDKITE_BRANCH', '') == 'trunk'
end

# Resolves dry-run vs real: an explicit argument wins, then the `PROMOTE_DRY_RUN`
# env override, then real only on trunk. The override is an env var (not a lane
# argument) because fastlane drops `key:false` CLI arguments.
def dry_run_for(explicit)
  explicit = nil if explicit.to_s.strip.empty?
  value = explicit.nil? ? ENV.fetch('PROMOTE_DRY_RUN', nil) : explicit
  return !real_promotion_run? if value.to_s.strip.empty?

  parse_dry_run_override(value)
end

# Strictly parses a dry-run override to a boolean. Only `true`/`false` are accepted
# — anything else errors rather than silently falling through to a real promotion
# (the override fails closed, toward safety).
def parse_dry_run_override(value)
  case value.to_s.strip.downcase
  when 'true' then true
  when 'false' then false
  else
    UI.user_error!("Invalid dry-run value #{value.inspect}; expected `true` or `false` (set via `PROMOTE_DRY_RUN` or the `dry_run:` argument).")
  end
end

def nightly_changelog(build_code:)
  "Nightly build #{build_code}."
end

# Resolves a Spaceship app by bundle id (defaults to WordPress). WordPress and
# Jetpack share a build code, so the default is enough to enumerate candidates;
# the per-app beta-group check passes each identifier explicitly.
def app_store_connect_app(bundle_identifier = WORDPRESS_BUNDLE_IDENTIFIER)
  unless @app_store_connect_token_set
    Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(**app_store_connect_api_key)
    @app_store_connect_token_set = true
  end

  (@app_store_connect_apps ||= {})[bundle_identifier] ||= begin
    app = Spaceship::ConnectAPI::App.find(bundle_identifier)
    UI.user_error!("Could not find app #{bundle_identifier} in App Store Connect") if app.nil?
    app
  end
end

# Newest processed builds — used to find the last build of the day (nightly).
def app_store_connect_valid_builds
  Spaceship::ConnectAPI::Build.all(
    app_id: app_store_connect_app.id,
    processing_states: 'VALID',
    includes: 'preReleaseVersion',
    sort: '-uploadedDate',
    limit: 50
  )
rescue StandardError => e
  UI.user_error!("Unable to list builds from App Store Connect: #{e.message}")
end

# The newest processed build within the lookback window, or nil on a quiet day.
def latest_build_of_the_day
  cutoff = Time.now - (NIGHTLY_LOOKBACK_HOURS * 3600)
  app_store_connect_valid_builds.find { |build| (uploaded = parse_time(build.uploaded_date)) && uploaded > cutoff }
end

# Posts the per-app outcome of a promotion.
def post_promotion_result_to_slack(build_code:, app_version:, results:, dry_run: false, tier: 'public beta')
  status_lines = results.map do |app, result|
    next "• #{app}: :x: #{result[:error]}" unless result[:ok]

    "• #{app}: :white_check_mark: #{dry_run ? "would be submitted to #{tier} (dry run)" : "submitted to #{tier}"}"
  end

  all_ok = results.values.all? { |result| result[:ok] }
  header = if dry_run
             ":test_tube: *#{tier.capitalize} promotion — dry run* (nothing was actually distributed)"
           elsif all_ok
             ":rocket: *Promoted to #{tier}*"
           else
             ":warning: *#{tier.capitalize} promotion finished with errors*"
           end

  send_slack_message(
    message: <<~MSG
      #{header} — `#{build_code}` (#{app_version})

      #{status_lines.join("\n")}
    MSG
  )
end

# Parses an ISO-8601 timestamp, returning nil instead of raising.
def parse_time(value)
  Time.parse(value.to_s)
rescue StandardError
  nil
end
