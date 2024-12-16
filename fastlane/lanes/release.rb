# frozen_string_literal: true

# Lanes related to the Release Process (Code Freeze, Betas, Final Build, AppStore Submission…)
#
platform :ios do
  # Executes the initial steps of the code freeze
  #
  # - Cuts a new release branch
  # - Extracts the Release Notes
  # - Freezes the GitHub milestone and enables the GitHub branch protection for the new branch
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Executes the initial steps needed during code freeze'
  lane :code_freeze do |options|
    ensure_git_status_clean

    # Check out the up-to-date default branch, the designated starting point for the code freeze
    Fastlane::Helper::GitHelper.checkout_and_pull(DEFAULT_BRANCH)

    # Checks if internal dependencies are on a stable version
    check_pods_references

    # Make sure that Gutenberg is configured as expected for a successful code freeze
    gutenberg_dep_check

    release_branch_name = compute_release_branch_name(options: options, version: release_version_next)
    ensure_branch_does_not_exist!(release_branch_name)

    # The `release_version_next` is used as the `new internal release version` value because the external and internal
    # release versions are always the same.
    message = <<~MESSAGE
      Code Freeze:
      • New release branch from #{DEFAULT_BRANCH}: #{release_branch_name}

      • Current release version and build code: #{release_version_current} (#{build_code_current}).
      • New release version and build code: #{release_version_next} (#{build_code_code_freeze}).
    MESSAGE

    UI.important(message)

    skip_user_confirmation = options[:skip_confirm]

    UI.user_error!('Aborted by user request') unless skip_user_confirmation || UI.confirm('Do you want to continue?')

    UI.message 'Creating release branch...'
    Fastlane::Helper::GitHelper.create_branch(release_branch_name, from: DEFAULT_BRANCH)
    UI.success "Done! New release branch is: #{git_branch}"

    # Bump the release version and build code and write it to the `xcconfig` file
    UI.message 'Bumping release version and build code...'
    PUBLIC_VERSION_FILE.write(
      version_short: release_version_next,
      version_long: build_code_code_freeze
    )
    UI.success "Done! New Release Version: #{release_version_current}. New Build Code: #{build_code_current}"

    commit_version_and_build_files

    new_version = release_version_current

    release_notes_source_path = File.join(PROJECT_ROOT_FOLDER, 'RELEASE-NOTES.txt')
    extract_release_notes_for_version(
      version: new_version,
      release_notes_file_path: release_notes_source_path,
      extracted_notes_file_path: extracted_release_notes_file_path(app: :wordpress)
    )
    # It would be good to update the action so that it can:
    #
    # - Use a custom commit message, so that we can differentiate between
    #   WordPress and Jetpack
    # - Have some sort of interactive mode, where the file is extracted and
    #   shown to the user and they can either confirm and let the lane commit,
    #   or modify it manually first and then run through the
    #   show-confirm-commit cycle again
    #
    # In the meantime, we can make due with a duplicated commit message and the
    # `print_release_notes_reminder` at the end of the lane to remember to make
    # updates to the files.
    extract_release_notes_for_version(
      version: new_version,
      release_notes_file_path: release_notes_source_path,
      extracted_notes_file_path: extracted_release_notes_file_path(app: :jetpack)
    )
    ios_update_release_notes(
      new_version: new_version,
      release_notes_file_path: release_notes_source_path
    )

    unless skip_user_confirmation || UI.confirm('Ready to push changes to remote to let the automation configure it on GitHub?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    # Protect release/* branch
    copy_branch_protection(
      repository: GITHUB_REPO,
      from_branch: DEFAULT_BRANCH,
      to_branch: release_branch_name
    )

    begin
      # Move PRs to next milestone
      moved_prs = update_assigned_milestone(
        repository: GITHUB_REPO,
        from_milestone: new_version,
        to_milestone: release_version_next,
        comment: "Version `#{new_version}` has now entered code-freeze, so the milestone of this PR has been updated to `#{release_version_next}`."
      )

      # Add ❄️ marker to milestone title to indicate we entered code-freeze
      set_milestone_frozen_marker(
        repository: GITHUB_REPO,
        milestone: new_version
      )
    rescue StandardError => e
      moved_prs = []

      report_milestone_error(error_title: "Error freezing milestone `#{new_version}`: #{e.message}")
    end

    UI.message("Moved the following PRs to milestone #{release_version_next}: #{moved_prs.join(', ')}")

    # Annotate the build with the moved PRs
    moved_prs_info = if moved_prs.empty?
                       "👍 No open PRs were targeting `#{new_version}` at the time of code-freeze"
                     else
                       "#{moved_prs.count} PRs targeting `#{new_version}` were still open and thus moved to `#{release_version_next}`:\n" \
                         + moved_prs.map { |pr_num| "[##{pr_num}](https://github.com/#{GITHUB_REPO}/pull/#{pr_num})" }.join(', ')
                     end

    buildkite_annotate(style: moved_prs.empty? ? 'success' : 'warning', context: 'start-code-freeze', message: moved_prs_info) if is_ci

    print_release_notes_reminder

    message = <<~MESSAGE
      Code freeze started successfully.

      Next steps:

      - Checkout `#{release_branch_name}` branch locally
      - Update pods and release notes
      - Finalize the code freeze
    MESSAGE
    buildkite_annotate(context: 'code-freeze-success', style: 'success', message: message) if is_ci
  end

  # Executes the final steps for the code freeze
  #
  #  - Generates `.strings` files from code then merges the other, manually-maintained `.strings` files with it
  #  - Triggers the build of the first beta on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Completes the final steps for the code freeze'
  lane :complete_code_freeze do |skip_confirm: false|
    ensure_git_branch_is_release_branch!
    ensure_git_status_clean

    version = release_version_current

    UI.important("Completing code freeze for: #{version}")

    UI.user_error!('Aborted by user request') unless skip_confirm || UI.confirm('Do you want to continue?')

    generate_strings_file_for_glotpress

    unless skip_confirm || UI.confirm('Ready to push changes to remote and trigger the beta build?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    trigger_beta_build

    pr_url = create_backmerge_pr
    message = <<~MESSAGE
      Code freeze completed successfully. Next, review and merge the [integration PR](#{pr_url}).
    MESSAGE
    buildkite_annotate(context: 'code-freeze-completed', style: 'success', message: message) if is_ci
  end

  # Creates a new beta by bumping the app version appropriately then triggering a beta build on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Trigger a new beta build on CI'
  lane :new_beta_release do |options|
    ensure_git_status_clean

    Fastlane::Helper::GitHelper.checkout_and_pull(DEFAULT_BRANCH)

    release_version = release_version_current

    # Check branch
    unless Fastlane::Helper::GitHelper.checkout_and_pull(compute_release_branch_name(options: options, version: release_version))
      UI.user_error!("Release branch for version #{release_version} doesn't exist.")
    end

    ensure_git_branch_is_release_branch! # This check is mostly redundant

    # The `release_version_next` is used as the `new internal release version` value because the external and internal
    # release versions are always the same.
    message = <<~MESSAGE
      • Current build code: #{build_code_current}
      • New build code: #{build_code_next}
    MESSAGE

    UI.important(message)

    skip_user_confirmation = options[:skip_confirm]

    UI.user_error!('Aborted by user request') unless skip_user_confirmation || UI.confirm('Do you want to continue?')

    generate_strings_file_for_glotpress
    download_localized_strings_and_metadata
    lint_localizations(allow_retry: skip_user_confirmation == false)

    bump_build_code

    unless skip_user_confirmation || UI.confirm('Ready to push changes to remote and trigger the beta build?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    trigger_beta_build

    pr_url = create_backmerge_pr
    message = <<~MESSAGE
      Beta deployment was successful. Next, review and merge the [integration PR](#{pr_url}).
    MESSAGE
    buildkite_annotate(context: 'beta-completed', style: 'success', message: message) if is_ci
  end

  lane :create_editorial_branch do |options|
    ensure_git_status_clean

    release_version = release_version_current

    unless Fastlane::Helper::GitHelper.checkout_and_pull(compute_release_branch_name(options: options, version: release_version))
      UI.user_error!("Release branch for version #{release_version} doesn't exist.")
    end

    ensure_git_branch_is_release_branch! # This check is mostly redundant

    git_pull

    Fastlane::Helper::GitHelper.create_branch(editorial_branch_name(version: release_version))

    unless options[:skip_confirm] || UI.confirm('Ready to push editorial branch to remote?')
      UI.message("Aborting as requested. Don't forget to push the branch to the remote manually.")
      next
    end

    # We need to also set upstream so the branch created in our local tracks the remote counterpart.
    # Otherwise, when the next automation step will run and try to push changes made on that branch, it will fail.
    push_to_git_remote(tags: false, set_upstream: true)
  end

  # Sets the stage to start working on a hotfix
  #
  # - Cuts a new `release/x.y.z` branch from the tag from the latest (`x.y`) version
  # - Bumps the app version numbers appropriately
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @option [String] version (required) The version number to use for the hotfix (`"x.y.z"`)
  #
  desc 'Creates a new hotfix branch for the given `version:x.y.z`. The branch will be cut from the `x.y` tag.'
  lane :new_hotfix_release do |options|
    # Verify that there's nothing in progress in the working copy
    ensure_git_status_clean

    new_version = options[:version] || UI.input('Version number for the new hotfix?')
    build_code_hotfix = build_code_hotfix(release_version: new_version)

    # Parse the provided version into an AppVersion object
    parsed_version = VERSION_FORMATTER.parse(new_version)
    previous_version = VERSION_FORMATTER.release_version(VERSION_CALCULATOR.previous_patch_version(version: parsed_version))

    # Check versions
    message = <<~MESSAGE
      New Hotfix:

      • Current release version and build code: #{release_version_current} (#{build_code_current}).
      • New release version and build code: #{new_version} (#{build_code_hotfix}).

      Branching from tag: #{previous_version}
    MESSAGE

    UI.important(message)
    UI.user_error!('Aborted by user request') unless options[:skip_confirm] || UI.confirm('Do you want to continue?')

    # Check tags
    UI.user_error!("Version #{new_version} already exists! Abort!") if git_tag_exists(tag: new_version)
    UI.user_error!("Version #{previous_version} is not tagged! A hotfix branch cannot be created.") unless git_tag_exists(tag: previous_version)

    # Create the hotfix branch
    UI.message 'Creating hotfix branch...'
    Fastlane::Helper::GitHelper.create_branch(compute_release_branch_name(options: options, version: new_version), from: previous_version)
    UI.success "Done! New hotfix branch is: #{git_branch}"

    # Bump the hotfix version and build code and write it to the `xcconfig` file
    UI.message 'Bumping hotfix version and build code...'
    PUBLIC_VERSION_FILE.write(
      version_short: new_version,
      version_long: build_code_hotfix
    )
    UI.success "Done! New Release Version: #{release_version_current}. New Build Code: #{build_code_current}"

    commit_version_and_build_files

    unless options[:skip_confirm] || UI.confirm('Ready to push changes to remote?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)
  end

  # Finalizes a hotfix, by triggering a release build on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Performs the final checks and triggers a release build for the hotfix in the current branch'
  lane :finalize_hotfix_release do |skip_confirm: false|
    ensure_git_branch_is_release_branch!
    ensure_git_status_clean

    hotfix_version = release_version_current

    UI.important("Triggering hotfix build for version: #{hotfix_version}")
    unless skip_confirm || UI.confirm('Do you want to continue?')
      UI.user_error!("Terminating as requested. Don't forget to run the remainder of this automation manually.")
    end

    trigger_release_build(branch_to_build: release_branch_name(version: hotfix_version))

    create_backmerge_pr

    # Close hotfix milestone
    begin
      close_milestone(
        repository: GITHUB_REPO,
        milestone: hotfix_version
      )
    rescue StandardError => e
      report_milestone_error(error_title: "Error closing milestone `#{hotfix_version}`: #{e.message}")
    end
  end

  # Finalizes a release at the end of a sprint to submit to the App Store, triggering the final release build on CI
  #
  # This lane performs the following actions:
  # - Updates store metadata
  # - Bumps final version number
  # - Removes branch protection and closes milestone
  # - Triggers the final release on CI
  #
  # @param skip_confirm [Boolean] Whether to skip confirmation prompts
  #
  lane :finalize_release do |skip_confirm: false|
    UI.user_error!('To finalize a hotfix, please use the `finalize_hotfix_release` lane instead') if current_version_hotfix?

    ensure_git_branch_is_release_branch!
    ensure_git_status_clean

    UI.important("Finalizing release: #{release_version_current}")
    UI.user_error!('Aborted by user request') unless skip_confirm || UI.confirm('Do you want to continue?')

    check_all_translations(interactive: skip_confirm == false)

    download_localized_strings_and_metadata
    lint_localizations(allow_retry: skip_confirm == false)

    bump_build_code

    unless skip_confirm || UI.confirm('Ready to push changes to remote and trigger the release build?')
      UI.user_error!("Terminating as requested. Don't forget to run the remainder of this automation manually.")
    end

    push_to_git_remote(tags: false)

    version = release_version_current

    trigger_release_build

    pr_url = create_backmerge_pr
    message = <<~MESSAGE
      Release successfully finalized. Next, review and merge the [integration PR](#{pr_url}).
    MESSAGE
    buildkite_annotate(context: 'finalization-completed', style: 'success', message: message) if is_ci

    # Close milestone
    begin
      set_milestone_frozen_marker(repository: GITHUB_REPO, milestone: version, freeze: false)
      close_milestone(repository: GITHUB_REPO, milestone: version)
    rescue StandardError => e
      report_milestone_error(error_title: "Error closing milestone `#{version}`: #{e.message}")
    end
  end

  # This lane publishes a release on GitHub and cleans up the release branch
  #
  # Note: We deliberately don't create backmerge PRs in this lane, unlike other apps.
  # This is because:
  # - Backmerge PRs can be problematic when the repo uses squash-merge
  # - Release branch changes should already be in the default branch at this point
  # For last-minute changes (e.g. due to app rejections), please create eventual backmerge PRs manually.
  #
  # @param [Boolean] skip_confirm (default: false) If set, will skip the confirmation prompt before running the rest of the lane
  #
  # @example Running the lane
  #          bundle exec fastlane publish_release skip_confirm:true
  #
  lane :publish_release do |skip_confirm: false|
    ensure_git_status_clean
    ensure_git_branch_is_release_branch!

    version_number = release_version_current
    current_branch = release_branch_name(version: version_number)

    UI.important <<~PROMPT
      Publish the #{version_number} release. This will:
      - Publish the existing draft `#{version_number}` release on GitHub
      - Which will also have GitHub create the associated git tag, pointing to the tip of the branch
      - Delete the `#{current_branch}` branch
    PROMPT
    unless skip_confirm || UI.confirm('Do you want to continue?')
      UI.user_error!("Terminating as requested. Don't forget to run the remainder of this automation manually.")
    end

    UI.important "Publishing release #{version_number} on GitHub"

    publish_github_release(
      repository: GITHUB_REPO,
      name: version_number
    )

    # The `publish_github_release` call should also create a tag, allowing us to safely delete the `release/*` branch.
    delete_remote_git_branch!(current_branch)
  end

  # Triggers a beta build on CI
  #
  # @option [String] branch The name of the branch we want the CI to build, e.g. `release/19.3`. Defaults to `release/<current version>`
  #
  lane :trigger_beta_build do |options|
    branch = compute_release_branch_name(options: options)
    trigger_buildkite_release_build(branch: branch, beta: true)
  end

  # Triggers a stable release build on CI
  #
  # @option [String] branch The name of the branch we want the CI to build, e.g. `release/19.3`. Defaults to `release/<current version>`
  #
  lane :trigger_release_build do |options|
    branch = compute_release_branch_name(options: options)
    trigger_buildkite_release_build(branch: branch, beta: false)
  end
end

#################################################
# Helper Functions
#################################################

# Triggers a Release Build on Buildkite
#
# @param [String] branch The branch to build
# @param [Boolean] beta Indicate if we should build a beta or regular release
#
def trigger_buildkite_release_build(branch:, beta:)
  environment = {
    IS_BETA_RELEASE: beta,
    RELEASE_VERSION: release_version_current
  }

  # If we're running on CI, we can directly start the release pipeline jobs within the same build
  if is_ci
    buildkite_pipeline_upload(
      pipeline_file: BUILDKITE_RELEASE_PIPELINE,
      environment: environment
    )
  else
    build_url = buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: branch,
      environment: environment,
      pipeline_file: BUILDKITE_RELEASE_PIPELINE,
      message: beta ? 'Beta Builds' : 'Release Builds'
    )

    UI.success("Release build triggered on #{branch}: #{build_url}")
  end
end

# Checks that the Gutenberg pod is reference by a tag and not a commit
#
desc 'Verifies that Gutenberg is referenced by release version and not by commit'
lane :gutenberg_dep_check do
  source = gutenberg_config![:ref]

  UI.user_error!('Gutenberg config does not contain expected key :ref') if source.nil?

  case [source[:tag], source[:commit]]
  when [nil, nil]
    UI.user_error!('Could not find any Gutenberg version reference.')
  when [nil, commit = source[:commit]]
    if UI.confirm("Gutenberg referenced by commit (#{commit}) instead than by tag. Do you want to continue anyway?")
      UI.message("Gutenberg version: #{commit}")
    else
      UI.user_error!('Aborting...')
    end
  else
    # If a tag is present, the commit value is ignored
    UI.message("Gutenberg version: #{source[:tag]}")
  end
end

lane :lint_localizations do |options|
  ios_lint_localizations(
    input_dir: 'WordPress/Resources',
    allow_retry: options.fetch(:allow_retry, true)
  )
end

# Returns the path to the extracted Release Notes file for the given `app`.
#
# @param [String|Symbol] app The app to get the path for, must be one of `wordpress` or `jetpack`
#
def extracted_release_notes_file_path(app:)
  paths = {
    wordpress: WORDPRESS_RELEASE_NOTES_PATH,
    jetpack: JETPACK_RELEASE_NOTES_PATH
  }
  paths[app.to_sym] || UI.user_error!("Invalid app name passed to lane: #{app}")
end

# Prints a reminder to audit the Release Notes after code freeze.
#
def print_release_notes_reminder
  message = <<~MSG
    The extracted release notes for WordPress and Jetpack were based on the same source.
    Don't forget to remove any item that doesn't apply to the respective app before editorialization.

    You can find the extracted notes at:

    - #{extracted_release_notes_file_path(app: :wordpress)}
    - #{extracted_release_notes_file_path(app: :jetpack)}
  MSG

  message.lines.each { |l| UI.important(l.chomp) }
end

# Wrapper around Fastlane `UI.confirm` that adds the option to bypass the
# prompt if a given flag is true
#
# @param [String] message The text to pass to `UI.confirm` to show the user
# @param [Boolean] bypass A flag that allows bypassing the `UI.confirm` prompt, i.e. acting as if the prompt returned `true`
def prompt_for_confirmation(message:, bypass:)
  return true if bypass

  UI.confirm(message)
end

def bump_build_code
  bump_production_build_code
  commit_version_and_build_files
end

def bump_production_build_code
  UI.message 'Bumping build code...'
  PUBLIC_VERSION_FILE.write(version_long: build_code_next)
  UI.success "Done. New Build Code: #{build_code_current}"
end

def commit_version_and_build_files
  git_commit(
    path: PUBLIC_CONFIG_FILE,
    message: 'Bump version number',
    allow_nothing_to_commit: false
  )
end

def create_backmerge_pr(source_branch: release_branch_name, target_branch: nil)
  pr_url = create_release_backmerge_pull_request(
    repository: GITHUB_REPO,
    source_branch: source_branch,
    target_branches: Array(target_branch),
    labels: ['Releases'],
    milestone_title: release_version_next
  )
rescue StandardError => e
  error_message = <<-MESSAGE
    Error creating backmerge pull request:

    #{e.message}

    If this is not the first time you are running the automation that creates a backmerge, the backmerge PR for the `#{source_branch}` branch might have already been previously created.
    Please close any previous backmerge PR for the `#{source_branch}` branch, delete the previous merge branch, then run the release task again.
  MESSAGE

  buildkite_annotate(style: 'error', context: 'error-creating-backmerge', message: error_message) if is_ci

  UI.user_error!(error_message)

  pr_url
end

def ensure_git_branch_is_release_branch!
  # Verify that the current branch is a release branch. Notice that `ensure_git_branch` expects a RegEx parameter
  ensure_git_branch(branch: '^release/')
end

def ensure_branch_does_not_exist!(branch_name)
  return unless Fastlane::Helper::GitHelper.branch_exists_on_remote?(branch_name: branch_name)

  error_message = "The branch `#{branch_name}` already exists. Please check first if there is an existing Pull Request that needs to be merged or closed first, " \
                  'or delete the branch to then run again the release task.'

  buildkite_annotate(style: 'error', context: 'error-checking-branch', message: error_message) if is_ci

  UI.user_error!(error_message)
end

# Delete a branch remotely, after having removed any GitHub branch protection
#
def delete_remote_git_branch!(branch_name)
  remove_branch_protection(repository: GITHUB_REPO, branch: branch_name)

  Git.open(Dir.pwd).push('origin', branch_name, delete: true)
end

def report_milestone_error(error_title:)
  error_message = <<-MESSAGE
    #{error_title}

    - If this is not the first time you are running the release task (e.g. retrying because it failed on first attempt), the milestone might have already been closed and this error is expected.
    - Otherwise if this is the first you are running the release task for this version, please investigate the error.
  MESSAGE

  UI.error(error_message)

  buildkite_annotate(style: 'warning', context: 'error-with-milestone', message: error_message) if is_ci
end

def check_pods_references
  result = ios_check_beta_deps(lockfile: File.join(PROJECT_ROOT_FOLDER, 'Podfile.lock'))

  style = result[:pods].nil? || result[:pods].empty? ? 'success' : 'warning'
  message = "### Checking Internal Dependencies are all on a **stable** version\n\n#{result[:message]}"
  buildkite_annotate(context: 'pods-check', style: style, message: message) if is_ci
end
