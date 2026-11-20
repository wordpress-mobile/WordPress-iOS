# frozen_string_literal: true

require_relative 'placeholder_changes'

# Continuous translations (Faster Releases, Phase 2).
#
# Two jobs keep strings flowing between trunk and GlotPress without waiting for a code freeze:
#
# - `upload_strings_for_translation` runs on every trunk build. It regenerates the English `Localizable.strings`
#   from code and keeps one bot PR up to date with the result. GlotPress imports the English file from trunk once
#   that PR merges.
# - `sync_translations` runs daily. It downloads the latest human translations from GlotPress and keeps a second
#   bot PR up to date with them.
#
# Both PRs reuse one long-lived branch each (dependabot-style), turn on auto-merge, and go through the merge queue
# like any other PR. Neither job ships machine translations: the plural fold inside `download_localized_strings`
# only stages them in `Plurals.xcstrings`, which the app doesn't read yet (see docs/localization-pipeline.md).
#
# Both lanes only push and open PRs when run by CI on `trunk`. Anywhere else they do the same work, report what
# they would publish, and stop — so they're safe to run from a PR build or locally on a scratch checkout.

STRINGS_FOR_TRANSLATION_BRANCH = 'bot/strings-for-translation'
TRANSLATION_SYNC_BRANCH = 'bot/translation-sync'
CONTINUOUS_TRANSLATION_PR_LABELS = ['i18n'].freeze

platform :ios do
  # Regenerates the English strings from code and opens (or updates) the PR that sends them to GlotPress.
  #
  # Fails if an existing key changed its format arguments — see `PlaceholderChanges`.
  #
  # @called_by CI, on every trunk build
  #
  desc 'Regenerate the English strings and open or update the PR that sends them to GlotPress'
  lane :upload_strings_for_translation do
    publish = continuous_translation_publish_run?
    ensure_git_status_clean
    base_sha = sh('git', 'rev-parse', 'HEAD', log: false).strip

    sh('git', 'checkout', '-B', STRINGS_FOR_TRANSLATION_BRANCH)
    generate_strings_file_for_glotpress # commits 'Update strings for localization', if anything changed

    en_strings = File.join(WORDPRESS_EN_LPROJ, 'Localizable.strings')
    check_placeholder_changes(base_sha: base_sha, path: en_strings)

    publish_continuous_translation_pr(
      publish: publish,
      base_sha: base_sha,
      branch: STRINGS_FOR_TRANSLATION_BRANCH,
      superseded_by_newer_builds: true,
      pr_text: {
        title: 'Update strings for localization',
        body: <<~BODY
          Automated: the English `Localizable.strings` regenerated from code on `trunk`. Once this merges, GlotPress imports the new and changed strings so translators can start on them.

          This PR is updated in place after every `trunk` build and merges through the merge queue once it's approved. See `docs/localization-pipeline.md`.
        BODY
      }
    )
  end

  # Downloads the latest human translations from GlotPress and opens (or updates) the PR that brings them in.
  #
  # @called_by CI, daily (`.buildkite/translation-sync.yml`)
  #
  desc 'Download the latest translations from GlotPress and open or update the PR that brings them in'
  lane :sync_translations do
    publish = continuous_translation_publish_run?
    ensure_git_status_clean
    base_sha = sh('git', 'rev-parse', 'HEAD', log: false).strip

    sh('git', 'checkout', '-B', TRANSLATION_SYNC_BRANCH)
    download_localized_strings # commits each kind of downloaded file separately, if anything changed
    lint_localizations(allow_retry: false)

    publish_continuous_translation_pr(
      publish: publish,
      base_sha: base_sha,
      branch: TRANSLATION_SYNC_BRANCH,
      superseded_by_newer_builds: false,
      pr_text: {
        title: 'Update translations',
        body: <<~BODY
          Automated: the latest human translations from GlotPress.

          This PR is updated in place every day and merges through the merge queue once it's approved. It contains no machine translations. See `docs/localization-pipeline.md`.
        BODY
      }
    )
  end
end

#################################################
# Helpers
#################################################

# True only for a CI build of `trunk` (including scheduled builds). Every other run is a dry run: it does the work
# and reports what it would publish, but never pushes or touches GitHub.
def continuous_translation_publish_run?
  is_ci && ENV.fetch('BUILDKITE_BRANCH', '') == DEFAULT_BRANCH
end

# Fails if any English string that existed at `base_sha` changed its format arguments in the working tree.
def check_placeholder_changes(base_sha:, path:)
  changes = PlaceholderChanges.incompatible(
    strings_at_commit(sha: base_sha, path: path),
    Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: File.join(PROJECT_ROOT_FOLDER, path))
  )
  if changes.empty?
    UI.success('No existing string changed its format arguments.')
    return
  end

  report_placeholder_changes(changes)
  UI.user_error!(
    "#{changes.size} existing string(s) changed their format arguments but kept their key. " \
    'Existing translations still use the old arguments and would crash or show the wrong value. ' \
    'Give the changed text a new key.'
  )
end

def strings_at_commit(sha:, path:)
  Dir.mktmpdir do |dir|
    old_path = File.join(dir, File.basename(path))
    File.write(old_path, sh('git', 'show', "#{sha}:#{path}", log: false))
    Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: old_path)
  end
end

def report_placeholder_changes(changes)
  changes.each do |change|
    UI.error(change.key)
    UI.error("    was: #{change.old_value.inspect}")
    UI.error("    now: #{change.new_value.inspect}")
    UI.error("    #{change.reason}")
  end
end

# Pushes the commits made on top of `base_sha` to `branch`, then opens a PR for it (or reuses the open one) and
# turns on auto-merge. Skips the push when the branch on GitHub already has the same changes, so an unrelated trunk
# commit doesn't restart the PR's checks.
#
# When nothing changed, `trunk` already has everything the bot PR would bring (for example, a release merge-back
# brought the same files in), so an open bot PR is out of date and gets closed rather than left to merge old files.
#
# `superseded_by_newer_builds` is for the per-build job: every `trunk` commit gets its own run, so a run for an
# older commit leaves publishing to the run for the newest one.
def publish_continuous_translation_pr(publish:, base_sha:, branch:, superseded_by_newer_builds:, pr_text:)
  changed_files = changed_files_since(base_sha)

  unless publish
    UI.important("Dry run: not touching `#{branch}` or its PR (publishing only happens on CI for `#{DEFAULT_BRANCH}`).")
    return
  end

  if superseded_by_newer_builds && !newest_trunk_commit?(base_sha)
    UI.important("`#{DEFAULT_BRANCH}` has moved past #{base_sha[0, 10]}. The build for the newer commit will update the PR instead.")
    return
  end

  if changed_files.empty?
    UI.success('Nothing changed — no PR needed.')
    close_stale_continuous_translation_pr(branch: branch)
    return
  end

  push_continuous_translation_branch(branch: branch, base_sha: base_sha, changed_files: changed_files)
  open_or_update_continuous_translation_pr(branch: branch, title: pr_text[:title], body: pr_text[:body])
end

def push_continuous_translation_branch(branch:, base_sha:, changed_files:)
  if remote_branch_has_same_changes?(branch: branch, base_sha: base_sha, changed_files: changed_files)
    UI.success("`#{branch}` on GitHub already has these changes — not pushing.")
  else
    sh('git', 'push', '--force', 'origin', "HEAD:refs/heads/#{branch}")
  end
end

def changed_files_since(base_sha)
  files = git_lines('diff', '--name-only', "#{base_sha}..HEAD")
  UI.message("Changes on top of #{base_sha[0, 10]}:\n#{sh('git', 'diff', '--stat', "#{base_sha}..HEAD", log: false)}") unless files.empty?
  files
end

def git_lines(*)
  sh('git', *, log: false).split("\n").map(&:strip).reject(&:empty?)
end

# A slow build of an older trunk commit must not overwrite the PR with older strings.
def newest_trunk_commit?(sha)
  sh('git', 'fetch', '--quiet', 'origin', DEFAULT_BRANCH)
  sh('git', 'rev-parse', 'FETCH_HEAD', log: false).strip == sha
end

def remote_branch_has_same_changes?(branch:, base_sha:, changed_files:)
  return false if sh('git', 'ls-remote', '--heads', 'origin', branch, log: false).strip.empty?

  sh('git', 'fetch', '--quiet', 'origin', branch)
  remote_sha = sh('git', 'rev-parse', 'FETCH_HEAD', log: false).strip
  # Compare every file either side changed, so a file the remote branch changed but this run didn't also counts.
  files = (changed_files + git_lines('diff', '--name-only', "#{base_sha}...#{remote_sha}")).uniq
  system('git', 'diff', '--quiet', remote_sha, 'HEAD', '--', *files)
end

def open_or_update_continuous_translation_pr(branch:, title:, body:)
  github = Fastlane::Helper::GithubHelper.new(github_token: get_required_env('GITHUB_TOKEN'))
  pull_request = find_or_create_continuous_translation_pr(github: github, branch: branch, title: title, body: body)
  enable_auto_merge(client: github.client, pull_request: pull_request)
  return unless is_ci

  buildkite_annotate(context: "continuous-translation-#{branch.tr('/', '-')}", style: 'info', message: "PR: #{pull_request.html_url}")
end

def find_or_create_continuous_translation_pr(github:, branch:, title:, body:)
  existing = github.find_pull_request(repository: GITHUB_REPO, head: branch, base: DEFAULT_BRANCH)
  if existing
    UI.success("Updated the existing PR: #{existing.html_url}")
    return existing
  end

  pull_request = github.client.create_pull_request(GITHUB_REPO, DEFAULT_BRANCH, branch, title, body)
  github.client.add_labels_to_an_issue(GITHUB_REPO, pull_request.number, CONTINUOUS_TRANSLATION_PR_LABELS)
  UI.success("Opened a PR: #{pull_request.html_url}")
  pull_request
end

def close_stale_continuous_translation_pr(branch:)
  github = Fastlane::Helper::GithubHelper.new(github_token: get_required_env('GITHUB_TOKEN'))
  stale = github.find_pull_request(repository: GITHUB_REPO, head: branch, base: DEFAULT_BRANCH)
  return if stale.nil?

  github.client.add_comment(GITHUB_REPO, stale.number, "Closing: `#{DEFAULT_BRANCH}` already has these changes. The next run that finds new changes will open a new PR.")
  github.client.close_pull_request(GITHUB_REPO, stale.number)
  UI.success("Closed the out-of-date PR: #{stale.html_url}")
end

# With a merge queue, auto-merge adds the PR to the queue once it's approved and its checks pass. It stays on
# across force-pushes, so this is only needed once per PR — but turning it on again is harmless, so failures
# here (it's already on, or the PR is already queued) are logged rather than fatal.
def enable_auto_merge(client:, pull_request:)
  mutation = 'mutation($id: ID!) { enablePullRequestAutoMerge(input: { pullRequestId: $id }) { clientMutationId } }'
  # The body must be a JSON string. Given a Hash, Octokit takes its `query:` key as URL parameters and the
  # request never reaches GitHub.
  response = client.post('/graphql', { query: mutation, variables: { id: pull_request.node_id } }.to_json)
  errors = Array(response[:errors])
  if errors.empty?
    UI.success('Auto-merge is on.')
  else
    UI.important("Couldn't turn on auto-merge: #{errors.map { |error| error[:message] }.join('; ')}")
  end
rescue StandardError => e
  UI.important("Couldn't turn on auto-merge: #{e.message}")
end
