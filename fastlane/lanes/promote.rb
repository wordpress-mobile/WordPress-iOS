# frozen_string_literal: true

require 'json'
require 'net/http'
require 'spaceship'
require 'time'
require 'yaml'

# Promotes an already-uploaded TestFlight build through the beta tiers without
# rebuilding — each promotion is a metadata-only App Store Connect call:
#
#   per-commit  → internal TestFlight (see build.rb)
#   daily 00:00 → `promote_nightly_build`: last build of the day → nightly group
#   weekly      → `promote_build`: a developer picks from the nightly group → public group
#
# WordPress and Jetpack share a build code (same CI run), so one build promotes both.

PROMOTION_CANDIDATE_LIMIT = 12
PROMOTION_MAX_AGE_DAYS = 7
NIGHTLY_LOOKBACK_HOURS = 24

# Caps pilot's wait for App Store Connect build processing. We promote builds that
# are already uploaded and processed, so this resolves in seconds (CI #32892 saw
# ~1.3s/app); the cap exists only so a build that never resolves — a wrong/typo'd
# code, a deleted build, a marketing-version mismatch — fails the lane instead of
# hanging BuildWatcher, which polls forever when no timeout is set.
PROMOTION_PROCESSING_TIMEOUT_SECONDS = 15 * 60

# External beta groups, by tier. The public groups differ per app; both apps share a
# single nightly group, so one list covers both.
WORDPRESS_PUBLIC_BETA_GROUPS = ['Public Beta Testers'].freeze
JETPACK_PUBLIC_BETA_GROUPS = ['Beta Testers'].freeze
NIGHTLY_BETA_GROUP_NAME = 'Nightly Beta Testers'
NIGHTLY_BETA_GROUPS = [NIGHTLY_BETA_GROUP_NAME].freeze

# The block step writes the chosen build code here; the promote step reads it back.
# NOTE: `.buildkite/commands/promote-build-to-public.sh` reads this same key as a bare
# string literal (`meta-data get "build_to_promote"`) — keep the two in sync.
PROMOTION_META_DATA_KEY = 'build_to_promote'
# Matched via the Buildkite API to find the block step's job and build its unblock URL.
PROMOTION_BLOCK_LABEL = ':testflight: Promote to public beta'
PROMOTION_BLOCK_STEP_KEY = 'promote_to_public_beta_block'

# Written verbatim into the generated steps so `buildkite-agent pipeline upload` interpolates it.
CI_TOOLKIT_PLUGIN_REF = '$CI_TOOLKIT_PLUGIN'

# Where the gather lane writes the generated block + promote steps (gitignored `build/`).
PROMOTION_STEPS_FILE = File.join(PROJECT_ROOT_FOLDER, 'build', 'promote-steps.yml')

platform :ios do
  # Lists the nightly builds in Slack and opens a block step for a developer to
  # pick one. Uploads the steps here (not from the CI script) so it can read back
  # the block step's job id for the Slack unblock-dialog link.
  #
  # @called_by CI (`.buildkite/commands/gather-testflight-candidates.sh`)
  desc 'Gather candidate internal TestFlight builds and open the promotion block step'
  lane :gather_testflight_candidates do
    # Same guard as the promote lanes: a stray off-trunk run shouldn't read App Store
    # Connect, open a block step, or post a candidate list. The rescue below surfaces the
    # refusal to Slack so it isn't a silent red job.
    ensure_promotion_on_trunk!

    candidates = fetch_promotion_candidates

    if candidates.empty?
      notify_slack(":testflight: *Weekly public beta promotion* — no eligible builds in the `#{NIGHTLY_BETA_GROUP_NAME}` group. Nothing to promote this week.")
      UI.important('No promotion candidates found; skipping block step generation.')
      next
    end

    write_promotion_steps_file(candidates: candidates)
    upload_promotion_steps
    post_candidates_to_slack(candidates: candidates, pick_url: promotion_unblock_dialog_url)

    UI.success("Prepared #{candidates.count} promotion candidate(s) and opened the block step.")
  rescue StandardError => e
    # A real failure here should be as visible as the benign "nothing to promote" case;
    # otherwise the weekly run just shows a red job and the channel hears nothing.
    notify_slack(":x: *Weekly public beta promotion* failed before the picker could open — #{e.message}")
    raise
  end

  # Distributes the chosen build to the public beta group for both apps.
  #
  # @param [String] build_code The four-part build code to promote, e.g. `27.0.0.4571`.
  # @called_by CI (`.buildkite/commands/promote-build-to-public.sh`)
  desc 'Promote an existing internal TestFlight build to public beta (WordPress + Jetpack)'
  lane :promote_build do |build_code: nil|
    # Set once the per-app result has been posted, so the rescue doesn't double-report a
    # failure the result post already covered.
    result_posted = false
    ensure_promotion_on_trunk!

    build_code = build_code.to_s.strip
    UI.user_error!('`build_code` is required, e.g. `build_code:27.0.0.4571`') if build_code.empty?

    app_version = marketing_version_for_build_code(build_code)
    UI.important("Promoting build #{build_code} (version #{app_version}) to public beta for WordPress and Jetpack")

    results = distribute_build_to_apps(
      build_code: build_code,
      app_version: app_version,
      app_groups: public_beta_app_groups,
      changelog: public_beta_changelog(build_code: build_code)
    )

    post_promotion_result_to_slack(build_code: build_code, app_version: app_version, results: results, tier: 'public beta')
    result_posted = true

    failed = results.reject { |_, result| result[:ok] }.keys
    UI.user_error!("Promotion failed for: #{failed.join(', ')}") unless failed.empty?

    UI.success("Promoted #{build_code} to public beta for: #{results.keys.join(', ')}")
  rescue StandardError => e
    # A failure before the result post (bad build code, App Store Connect outage, off-trunk)
    # would otherwise be a silent red job — surface it to Slack the way gather does. Skip
    # when the result post already reported per-app status, to avoid a duplicate message.
    notify_slack(":x: *Public beta promotion* failed — #{e.message}") unless result_posted
    raise
  end

  # Promotes the last processed build of the day to the nightly group for both
  # apps. Automatic on a daily schedule; the weekly promotion picks from this group.
  #
  # @called_by CI (`.buildkite/commands/promote-nightly.sh`)
  desc 'Promote the last build of the day to the nightly beta group (WordPress + Jetpack)'
  lane :promote_nightly_build do
    # Set once the per-app result has been posted, so the rescue doesn't double-report a
    # failure the result post already covered.
    result_posted = false
    ensure_promotion_on_trunk!

    build = latest_build_of_the_day
    if build.nil?
      UI.important("No build uploaded in the last #{NIGHTLY_LOOKBACK_HOURS}h; nothing to promote to nightly.")
      next
    end

    build_code = build.version
    # We already hold the build object, so read its authoritative marketing version
    # directly. (promote_build starts from a bare build code, so it looks this up.)
    app_version = build.pre_release_version&.version
    UI.important("Promoting last build of the day #{build_code} (version #{app_version}) to nightly beta for WordPress and Jetpack")

    results = distribute_build_to_apps(
      build_code: build_code,
      app_version: app_version,
      app_groups: nightly_beta_app_groups,
      changelog: nightly_changelog(build_code: build_code)
    )

    post_promotion_result_to_slack(build_code: build_code, app_version: app_version, results: results, tier: 'nightly')
    result_posted = true

    failed = results.reject { |_, result| result[:ok] }.keys
    UI.user_error!("Nightly promotion failed for: #{failed.join(', ')}") unless failed.empty?

    UI.success("Promoted #{build_code} to nightly for: #{results.keys.join(', ')}")
  rescue StandardError => e
    # The nightly job runs unattended, so a failure before the result post (App Store
    # Connect outage, off-trunk) must not be a silent red job — surface it to Slack. Skip
    # when the result post already reported per-app status, to avoid a duplicate message.
    notify_slack(":x: *Nightly promotion* failed — #{e.message}") unless result_posted
    raise
  end
end

#################################################
# Helper Functions
#################################################

# Distributes a build to each app's groups, returning a per-app `{ ok:, error: }`
# result. A failure for one app doesn't stop the other.
def distribute_build_to_apps(build_code:, app_version:, app_groups:, changelog:)
  app_groups.to_h do |app|
    result =
      begin
        promote_existing_build_to_groups(app: app, app_version: app_version, build_code: build_code, changelog: changelog)
        { ok: true }
      rescue StandardError => e
        UI.error("Failed to promote #{app[:name]} (#{build_code}): #{e.message}")
        { ok: false, error: e.message }
      end
    [app[:name], result]
  end
end

def public_beta_app_groups
  [
    { name: 'WordPress', identifier: WORDPRESS_BUNDLE_IDENTIFIER, groups: WORDPRESS_PUBLIC_BETA_GROUPS },
    { name: 'Jetpack', identifier: JETPACK_BUNDLE_IDENTIFIER, groups: JETPACK_PUBLIC_BETA_GROUPS }
  ]
end

def nightly_beta_app_groups
  [
    { name: 'WordPress', identifier: WORDPRESS_BUNDLE_IDENTIFIER, groups: NIGHTLY_BETA_GROUPS },
    { name: 'Jetpack', identifier: JETPACK_BUNDLE_IDENTIFIER, groups: NIGHTLY_BETA_GROUPS }
  ]
end

# `distribute_only: true` locates the existing build (by marketing version + build
# code) and adds it to the named external groups for beta review — no new binary.
def promote_existing_build_to_groups(app:, app_version:, build_code:, changelog:)
  # Verify groups first: pilot silently skips any group name it can't match (reporting
  # success while distributing to zero testers), so we fail loudly instead.
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
    # Fail (rather than hang forever) if the build never resolves — see PROMOTION_PROCESSING_TIMEOUT_SECONDS.
    wait_processing_timeout_duration: PROMOTION_PROCESSING_TIMEOUT_SECONDS,
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

# Resolves a build's authoritative marketing version (CFBundleShortVersionString) from
# App Store Connect by its build code. distribute_only matches on this value exactly, so we
# look it up rather than guessing from the build code's parts — guessing breaks for any
# version that isn't two-part (e.g. hotfixes like `27.0.1`). Doubles as an existence check:
# an unknown build code fails here, fast, instead of hanging the distribute step.
def marketing_version_for_build_code(build_code)
  build =
    begin
      Spaceship::ConnectAPI::Build.all(
        app_id: app_store_connect_app.id,
        build_number: build_code,
        includes: 'preReleaseVersion',
        limit: 1
      ).first
    rescue StandardError => e
      UI.user_error!("Unable to look up build #{build_code} in App Store Connect: #{e.message}")
    end

  version = build&.pre_release_version&.version
  UI.user_error!("No build #{build_code} found in App Store Connect (or it has no marketing version).") if version.to_s.empty?
  version
end

# The promote lanes distribute to real external testers and can be run by hand, so they must
# only ever promote from the scheduled `trunk` jobs. Any other branch — or a local run — is a
# mistake: fail loudly before touching App Store Connect.
def ensure_promotion_on_trunk!
  branch = ENV.fetch('BUILDKITE_BRANCH', '')
  return if branch == DEFAULT_BRANCH

  UI.user_error!("Promotion only runs on `#{DEFAULT_BRANCH}` (current branch: #{branch.empty? ? 'none' : "`#{branch}`"}). Refusing to proceed.")
end

# TODO: generate from the PRs merged since the previous public build. For now a
# minimal note, since external distribution requires a changelog.
def public_beta_changelog(build_code:)
  "Public beta build #{build_code}."
end

def nightly_changelog(build_code:)
  "Nightly build #{build_code}."
end

def fetch_promotion_candidates
  builds = scoped_nightly_builds
  return [] if builds.empty?

  buildkite_index = buildkite_builds_by_number
  builds.first(PROMOTION_CANDIDATE_LIMIT).map { |build| candidate_for(build, buildkite_index) }
end

# Nightly-group builds on the latest marketing line and within the recency window, newest first.
def scoped_nightly_builds
  builds = app_store_connect_nightly_builds
  return [] if builds.empty?

  latest_version = latest_marketing_version(builds)
  cutoff = Time.now - (PROMOTION_MAX_AGE_DAYS * 86_400)
  builds.select { |build| eligible_candidate?(build, latest_version, cutoff) }
end

def latest_marketing_version(builds)
  builds.filter_map { |build| build.pre_release_version&.version }.max_by { |version| Gem::Version.new(version) }
rescue ArgumentError => e
  UI.user_error!("App Store Connect returned a non-numeric marketing version (#{e.message}); cannot determine the latest line.")
end

def eligible_candidate?(build, latest_version, cutoff)
  version = build.pre_release_version&.version
  return false if version.nil? || latest_version.nil?

  # Compare semantically, not as raw strings: `27.0` and `27.0.0` are the same line. A
  # string `==` would drop every build whose version string differs from the representative
  # `latest_marketing_version` happened to pick. Both values were already validated as
  # numeric by `latest_marketing_version` (it builds `Gem::Version`s over the same set).
  return false unless Gem::Version.new(version) == Gem::Version.new(latest_version)

  uploaded = parse_time(build.uploaded_date)
  uploaded ? uploaded > cutoff : false
end

# Maps an App Store Connect build to a candidate hash, enriched with the matching Buildkite build's commit/PR.
def candidate_for(build, buildkite_index)
  build_code = build.version
  buildkite_build = buildkite_index[build_code.split('.').last]

  {
    build_code: build_code,
    # Cleaned but NOT truncated — the Buildkite select label truncates (see candidate_label);
    # the Slack list wants the full subject. Compute the age once here, not at each render site.
    subject: sanitize_subject(buildkite_build&.dig('message').to_s.lines.first&.strip),
    pr: buildkite_build && pull_request_number_from_message(buildkite_build['message']),
    age: relative_age(build.uploaded_date)
  }
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

# Newest processed builds — used to find the last build of the day (nightly). Fetches a
# single newest-first page: Build.all / app.get_builds internally `.all_pages` through the
# *entire* matching history (the `limit:` only sizes each page), but we only need the most
# recent few, so we call the client directly and take one page.
def app_store_connect_valid_builds
  Spaceship::ConnectAPI.get_builds(
    filter: { app: app_store_connect_app.id, processingState: 'VALID' },
    includes: 'preReleaseVersion',
    sort: '-uploadedDate',
    limit: 50
  ).to_models
rescue StandardError => e
  UI.user_error!("Unable to list builds from App Store Connect: #{e.message}")
end

# Processed builds in the nightly group — the candidate pool for the public promotion.
# Single newest-first page only (see app_store_connect_valid_builds for why we avoid the
# `.all_pages` helpers); 50 newest covers the recency window many times over.
def app_store_connect_nightly_builds
  app = app_store_connect_app
  group = app.get_beta_groups.find { |beta_group| beta_group.name == NIGHTLY_BETA_GROUP_NAME }
  UI.user_error!("Could not find the '#{NIGHTLY_BETA_GROUP_NAME}' beta group in App Store Connect") if group.nil?

  Spaceship::ConnectAPI.get_builds(
    filter: { app: app.id, betaGroups: group.id, processingState: 'VALID' },
    includes: 'preReleaseVersion',
    sort: '-uploadedDate',
    limit: 50
  ).to_models
rescue StandardError => e
  UI.user_error!("Unable to list nightly builds from App Store Connect: #{e.message}")
end

# The newest processed build within the lookback window, or nil on a quiet day.
def latest_build_of_the_day
  cutoff = Time.now - (NIGHTLY_LOOKBACK_HOURS * 3600)
  app_store_connect_valid_builds.find { |build| (uploaded = parse_time(build.uploaded_date)) && uploaded > cutoff }
end

# Recent trunk builds keyed by build number, for enriching candidates with commit/PR. Best-effort.
def buildkite_builds_by_number
  buildkite_recent_trunk_builds.each_with_object({}) do |build, index|
    number = build['number']
    index[number.to_s] = build unless number.nil?
  end
rescue StandardError => e
  message = "Could not fetch Buildkite builds for candidate enrichment (#{e.message}); the candidate list will omit commit/PR details and link to the build page instead of the picker."
  UI.important(message)
  notify_slack(":warning: *Weekly public beta promotion* — #{message}")
  {}
end

def buildkite_recent_trunk_builds
  org = ENV.fetch('BUILDKITE_ORGANIZATION_SLUG', BUILDKITE_ORGANIZATION)
  pipeline = ENV.fetch('BUILDKITE_PIPELINE_SLUG', BUILDKITE_PIPELINE)

  uri = URI("https://api.buildkite.com/v2/organizations/#{org}/pipelines/#{pipeline}/builds")
  uri.query = URI.encode_www_form(branch: DEFAULT_BRANCH, state: 'passed', per_page: 50)

  response = buildkite_api_get(uri)
  UI.user_error!("Buildkite API request failed (#{response.code}): #{response.body}") unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
rescue StandardError => e
  UI.user_error!("Unable to fetch recent builds from Buildkite: #{e.message}")
end

def buildkite_api_get(uri)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{buildkite_api_token}"
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
end

# A Buildkite API token with `read_builds` scope — `BUILDKITE_API_TOKEN` on CI,
# `BUILDKITE_TOKEN` locally (see fastlane/env/user.env-example). Deliberately does
# NOT borrow the Claude-analysis token: that secret is scoped to a different
# integration/queue and reusing it couples this flow to unrelated infrastructure.
def buildkite_api_token
  token = ENV.fetch('BUILDKITE_API_TOKEN', nil) || ENV.fetch('BUILDKITE_TOKEN', nil)
  UI.user_error!('No Buildkite API token found. Set `BUILDKITE_API_TOKEN` (or `BUILDKITE_TOKEN`).') if token.to_s.empty?
  token
end

# Extracts the squash-merge PR number, e.g. `25704` from `Fix thing (#25704)`. Uses the
# LAST `(#nnn)` on the subject line: GitHub appends the merge PR there, so an earlier match
# would be a quoted/reverted PR (`Revert "Fix (#100)" (#200)` → 200, not 100).
def pull_request_number_from_message(message)
  message.to_s.lines.first.to_s.scan(/\(#(\d+)\)/).last&.first
end

# Neutralizes only the characters that actually misbehave downstream — `$` (Buildkite
# interpolates it at pipeline upload) and the backtick (a Slack code-span delimiter) —
# then collapses whitespace. Apostrophes and quotes are left intact (YAML and Slack handle
# them) so a subject like `Don't ship` isn't mangled into `Don t ship`. Does NOT truncate:
# truncation is the Buildkite label's concern (see truncate_label), and the Slack list wants
# the full subject.
def sanitize_subject(text)
  text.to_s.gsub(/[`$]/, ' ').gsub(/\s+/, ' ').strip
end

# Truncates to a one-line length with an ellipsis — for the Buildkite select label, which
# should stay short. Not applied to the Slack list, which has no width constraint.
def truncate_label(text, limit: 60)
  text = text.to_s
  text.length > limit ? "#{text[0...limit].strip}…" : text
end

# Escapes the three characters Slack treats specially in message text, so a commit
# subject containing `<`, `>`, or `&` renders literally instead of mangling mrkdwn.
def slack_escape(text)
  text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
end

# Posts to Slack without letting a webhook hiccup abort the caller. Promotion outcomes
# (and the live block step) shouldn't hinge on the notification succeeding — and a failed
# result post must not swallow the explicit UI.user_error! the caller raises afterward.
def notify_slack(message)
  send_slack_message(message: message)
rescue StandardError => e
  UI.important("Slack notification failed (#{e.message}); continuing without it.")
end

def write_promotion_steps_file(candidates:)
  options = candidates.map { |candidate| { 'label' => candidate_label(candidate), 'value' => candidate[:build_code] } }

  steps = {
    'steps' => [
      {
        'block' => PROMOTION_BLOCK_LABEL,
        'key' => PROMOTION_BLOCK_STEP_KEY,
        'prompt' => 'Choose the internal TestFlight build to release to public beta testers. This promotes the matching WordPress and Jetpack builds.',
        # Keep the build "running" (not green) while it waits for a human.
        'blocked_state' => 'running',
        'fields' => [
          {
            'select' => 'Build to promote',
            'key' => PROMOTION_META_DATA_KEY,
            # No default, and required: an un-actioned unblock must not silently
            # promote whatever sorted newest — force an explicit human choice.
            'required' => true,
            'options' => options
          }
        ]
      },
      {
        'label' => ':rocket: Promote selected build to public beta',
        'command' => '.buildkite/commands/promote-build-to-public.sh',
        'plugins' => [CI_TOOLKIT_PLUGIN_REF],
        'agents' => { 'queue' => 'mac' }
      }
    ]
  }

  FileUtils.mkdir_p(File.dirname(PROMOTION_STEPS_FILE))
  # `line_width: -1` keeps each label on one line (no YAML folding).
  File.write(PROMOTION_STEPS_FILE, steps.to_yaml(line_width: -1))
  UI.message("Wrote promotion steps for #{candidates.count} build(s) to #{PROMOTION_STEPS_FILE}")
end

# Source `shared-pipeline-vars` first so `$CI_TOOLKIT_PLUGIN` is interpolated.
def upload_promotion_steps
  sh('bash', '-c', "cd '#{PROJECT_ROOT_FOLDER}' && source .buildkite/shared-pipeline-vars && buildkite-agent pipeline upload build/promote-steps.yml")
end

# The block step's unblock-dialog URL, or nil (callers fall back to the build URL).
def promotion_unblock_dialog_url
  org = ENV.fetch('BUILDKITE_ORGANIZATION_SLUG', BUILDKITE_ORGANIZATION)
  pipeline = ENV.fetch('BUILDKITE_PIPELINE_SLUG', BUILDKITE_PIPELINE)
  build_number = ENV.fetch('BUILDKITE_BUILD_NUMBER', nil)
  return nil if build_number.nil?

  job_id = block_step_job_id(org: org, pipeline: pipeline, build_number: build_number)
  return nil if job_id.nil?

  # Deliberately the `…/jobs/<id>/unblock_dialog` deep link, NOT the job's canonical
  # `web_url`: a blocked manual job is auto-hidden on the build page, so its `web_url`
  # doesn't actually surface the step. This dialog URL opens the picker directly.
  #
  # The `buildkite.com/organizations/<org>/pipelines/<pipeline>/…` path is correct and
  # intentional: it's the Buildkite *web* route for the unblock dialog (verified working).
  # It deliberately mirrors the REST API path shape (`api.buildkite.com/v2/organizations/…`)
  # but is a distinct, valid web-app URL — don't "simplify" it to the bare
  # `buildkite.com/<org>/<pipeline>/builds/<n>` build-page form, which can't surface the step.
  "https://buildkite.com/organizations/#{org}/pipelines/#{pipeline}/builds/#{build_number}/jobs/#{job_id}/unblock_dialog"
end

# Polls the build for the just-uploaded block step's job id (it takes a moment to register).
def block_step_job_id(org:, pipeline:, build_number:)
  uri = URI("https://api.buildkite.com/v2/organizations/#{org}/pipelines/#{pipeline}/builds/#{build_number}")

  5.times do |attempt|
    job = find_promotion_block_job(uri)
    return job['id'] if job

    sleep(2) unless attempt == 4
  end

  UI.important('Could not resolve the promotion block step job id; Slack will link to the build instead.')
  nil
rescue StandardError => e
  UI.important("Error resolving the block step job id (#{e.message}); Slack will link to the build instead.")
  nil
end

def find_promotion_block_job(uri)
  response = buildkite_api_get(uri)
  return nil unless response.is_a?(Net::HTTPSuccess)

  manual_jobs = JSON.parse(response.body).fetch('jobs', []).select { |job| job['type'] == 'manual' }

  # Match on the stable step key the block was generated with (PROMOTION_BLOCK_STEP_KEY);
  # fall back to the emoji-prefixed label only if the API didn't surface a step key, so a
  # second manual step whose label merely contains ours can't shadow the match.
  manual_jobs.find { |job| job['step_key'] == PROMOTION_BLOCK_STEP_KEY } ||
    manual_jobs.find { |job| job['label'].to_s.include?(PROMOTION_BLOCK_LABEL) }
end

def candidate_label(candidate)
  parts = [candidate[:build_code]]
  parts << "— #{truncate_label(candidate[:subject])}" unless candidate[:subject].to_s.empty?
  parts << "(##{candidate[:pr]})" unless candidate[:pr].nil?
  parts << "· #{candidate[:age]}" unless candidate[:age].nil?
  parts.join(' ')
end

# Posts the candidate list. Links straight to the unblock dialog when we resolved the block
# step's job id; otherwise says so explicitly and points at the build, so a degraded link
# (job id didn't register in time — see block_step_job_id) isn't mistaken for the picker.
def post_candidates_to_slack(candidates:, pick_url: nil)
  build_url = ENV.fetch('BUILDKITE_BUILD_URL', nil)

  candidate_lines = candidates.map { |candidate| slack_candidate_line(candidate) }

  choose_line =
    if pick_url
      "\n\n:point_right: <#{pick_url}|Choose a build to promote>"
    elsif build_url
      "\n\n:warning: Couldn't deep-link to the picker — open <#{build_url}|the build> and unblock the promotion step to choose a build."
    else
      ''
    end

  notify_slack(
    <<~MSG
      :testflight: *Weekly public beta promotion* — choose a build to release to public beta testers (WordPress + Jetpack).#{choose_line}

      *Candidates:*
      #{candidate_lines.join("\n")}
    MSG
  )
end

# One Slack bullet per candidate: build code, escaped subject, optional PR link and age.
def slack_candidate_line(candidate)
  pr_part = candidate[:pr] ? " (<https://github.com/#{GITHUB_REPO}/pull/#{candidate[:pr]}|##{candidate[:pr]}>)" : ''
  age_part = candidate[:age] ? " · _#{candidate[:age]}_" : ''
  "• `#{candidate[:build_code]}` — #{slack_escape(candidate[:subject])}#{pr_part}#{age_part}"
end

# Posts the per-app outcome of a promotion.
def post_promotion_result_to_slack(build_code:, app_version:, results:, tier: 'public beta')
  status_lines = results.map do |app, result|
    next "• #{app}: :x: #{result[:error]}" unless result[:ok]

    "• #{app}: :white_check_mark: submitted to #{tier}"
  end

  all_ok = results.values.all? { |result| result[:ok] }
  header = if all_ok
             ":rocket: *Promoted to #{tier}*"
           else
             ":warning: *#{tier.capitalize} promotion finished with errors*"
           end

  notify_slack(
    <<~MSG
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

# A coarse relative age like `3h ago` / `2d ago`, or nil if unparseable.
def relative_age(iso_timestamp)
  parsed = parse_time(iso_timestamp)
  return nil if parsed.nil?

  seconds = Time.now - parsed
  return 'just now' if seconds < 60

  minutes = (seconds / 60).floor
  return "#{minutes}m ago" if minutes < 60

  hours = (minutes / 60).floor
  return "#{hours}h ago" if hours < 48

  "#{(hours / 24).floor}d ago"
rescue StandardError
  nil
end
