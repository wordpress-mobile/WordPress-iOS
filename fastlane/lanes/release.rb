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
    # Verify that there's nothing in progress in the working copy
    ensure_git_status_clean

    # Check out the up-to-date default branch, the designated starting point for the code freeze
    Fastlane::Helper::GitHelper.checkout_and_pull(DEFAULT_BRANCH)

    # Make sure that Gutenberg is configured as expected for a successful code freeze
    gutenberg_dep_check

    release_branch_name = compute_release_branch_name(options:, version: release_version_next)

    # The `release_version_next` is used as the `new internal release version` value because the external and internal
    # release versions are always the same.
    message = <<~MESSAGE
      Code Freeze:
      • New release branch from #{DEFAULT_BRANCH}: #{release_branch_name}

      • Current release version and build code: #{release_version_current} (#{build_code_current}).
      • New release version and build code: #{release_version_next} (#{build_code_code_freeze}).

      • Current internal release version and build code: #{release_version_current_internal} (#{build_code_current_internal})
      • New internal release version and build code: #{release_version_next} (#{build_code_code_freeze_internal})
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

    # Bump the internal release version and build code and write it to the `xcconfig` file
    UI.message 'Bumping internal release version and build code...'
    INTERNAL_VERSION_FILE.write(
      # The external and internal release versions are always the same. Because the external release version was
      # already bumped, we want to just use the `release_version_current`
      version_short: release_version_current,
      version_long: build_code_code_freeze_internal
    )
    UI.success "Done! New Internal Release Version: #{release_version_current_internal}. New Internal Build Code: #{build_code_current_internal}"

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
      new_version:,
      release_notes_file_path: release_notes_source_path
    )

    unless skip_user_confirmation || UI.confirm('Ready to push changes to remote to let the automation configure it on GitHub?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    attempts = 0
    begin
      attempts += 1
      set_branch_protection(repository: GITHUB_REPO, branch: release_branch_name)
    rescue StandardError => e
      if attempts < 2
        sleep_time = 5
        UI.message("Failed to set branch protection on GitHub. Retrying in #{sleep_time} seconds in case it was because the API hadn't noticed the new branch yet.")
        sleep(sleep_time)
        retry
      else
        UI.error("Failed to set branch protection on GitHub after #{attempts} attempts")
        raise e
      end
    end

    setfrozentag(repository: GITHUB_REPO, milestone: new_version)

    ios_check_beta_deps(podfile: File.join(PROJECT_ROOT_FOLDER, 'Podfile'))
    print_release_notes_reminder

    message = <<~MESSAGE
      Code freeze started successfully.

      Next steps:

      - Checkout `#{release_branch_name}` branch locally
      - Update pods and release notes
      - Finalize the code freeze
    MESSAGE
    buildkite_annotate(context: 'code-freeze-success', style: 'success', message:) if is_ci
  end

  # Executes the final steps for the code freeze
  #
  #  - Generates `.strings` files from code then merges the other, manually-maintained `.strings` files with it
  #  - Triggers the build of the first beta on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Completes the final steps for the code freeze'
  lane :complete_code_freeze do |options|
    ensure_git_branch_is_release_branch

    # Verify that there's nothing in progress in the working copy
    ensure_git_status_clean

    version = release_version_current

    UI.important("Completing code freeze for: #{version}")

    skip_user_confirmation = options[:skip_confirm]

    UI.user_error!('Aborted by user request') unless skip_user_confirmation || UI.confirm('Do you want to continue?')

    generate_strings_file_for_glotpress

    unless skip_user_confirmation || UI.confirm('Ready to push changes to remote and trigger the beta build?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    trigger_beta_build

    pr_url = create_release_management_pull_request(
      release_version: version,
      base_branch: DEFAULT_BRANCH,
      title: "Merge #{version} code freeze"
    )

    message = <<~MESSAGE
      Code freeze completed successfully. Next, review and merge the [integration PR](#{pr_url}).
    MESSAGE
    buildkite_annotate(context: 'code-freeze-completed', style: 'success', message:) if is_ci
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
    unless Fastlane::Helper::GitHelper.checkout_and_pull(compute_release_branch_name(options:, version: release_version))
      UI.user_error!("Release branch for version #{release_version} doesn't exist.")
    end

    ensure_git_branch_is_release_branch # This check is mostly redundant

    # The `release_version_next` is used as the `new internal release version` value because the external and internal
    # release versions are always the same.
    message = <<~MESSAGE
      • Current build code: #{build_code_current}
      • New build code: #{build_code_next}

      • Current internal build code: #{build_code_current_internal}
      • New internal build code: #{build_code_next_internal}
    MESSAGE

    UI.important(message)

    skip_user_confirmation = options[:skip_confirm]

    UI.user_error!('Aborted by user request') unless skip_user_confirmation || UI.confirm('Do you want to continue?')

    generate_strings_file_for_glotpress
    download_localized_strings_and_metadata(options)
    lint_localizations(allow_retry: skip_user_confirmation == false)

    bump_build_codes

    unless skip_user_confirmation || UI.confirm('Ready to push changes to remote and trigger the beta build?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    trigger_beta_build

    # Create an intermediate branch to avoid conflicts when integrating the changes
    Fastlane::Helper::GitHelper.create_branch("new_beta/#{release_version}")
    push_to_git_remote(tags: false)

    pr_url = create_release_management_pull_request(
      release_version:,
      base_branch: DEFAULT_BRANCH,
      title: "Merge changes from #{build_code_current}"
    )

    message = <<~MESSAGE
      Beta deployment was successful. Next, review and merge the [integration PR](#{pr_url}).
    MESSAGE
    buildkite_annotate(context: 'beta-completed', style: 'success', message:) if is_ci
  end

  lane :create_editorial_branch do |options|
    ensure_git_status_clean

    release_version = release_version_current

    unless Fastlane::Helper::GitHelper.checkout_and_pull(compute_release_branch_name(options:, version: release_version))
      UI.user_error!("Release branch for version #{release_version} doesn't exist.")
    end

    ensure_git_branch_is_release_branch # This check is mostly redundant

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
    build_code_hotfix_internal = build_code_hotfix_internal(release_version: new_version)

    # Parse the provided version into an AppVersion object
    parsed_version = VERSION_FORMATTER.parse(new_version)
    previous_version = VERSION_FORMATTER.release_version(VERSION_CALCULATOR.previous_patch_version(version: parsed_version))

    # Check versions
    message = <<~MESSAGE
      New Hotfix:

      • Current release version and build code: #{release_version_current} (#{build_code_current}).
      • New release version and build code: #{new_version} (#{build_code_hotfix}).

      • Current internal release version and build code: #{release_version_current_internal} (#{build_code_current_internal}).
      • New internal release version and build code: #{new_version} (#{build_code_hotfix_internal}).

      Branching from tag: #{previous_version}
    MESSAGE

    UI.important(message)
    UI.user_error!('Aborted by user request') unless options[:skip_confirm] || UI.confirm('Do you want to continue?')

    # Check tags
    UI.user_error!("Version #{new_version} already exists! Abort!") if git_tag_exists(tag: new_version)
    UI.user_error!("Version #{previous_version} is not tagged! A hotfix branch cannot be created.") unless git_tag_exists(tag: previous_version)

    # Create the hotfix branch
    UI.message 'Creating hotfix branch...'
    Fastlane::Helper::GitHelper.create_branch(compute_release_branch_name(options:, version: new_version), from: previous_version)
    UI.success "Done! New hotfix branch is: #{git_branch}"

    # Bump the hotfix version and build code and write it to the `xcconfig` file
    UI.message 'Bumping hotfix version and build code...'
    PUBLIC_VERSION_FILE.write(
      version_short: new_version,
      version_long: build_code_hotfix
    )
    UI.success "Done! New Release Version: #{release_version_current}. New Build Code: #{build_code_current}"

    # Bump the internal hotfix version and build code and write it to the `xcconfig` file
    UI.message 'Bumping internal hotfix version and build code...'
    INTERNAL_VERSION_FILE.write(
      version_short: new_version,
      version_long: build_code_hotfix_internal
    )
    UI.success "Done! New Internal Release Version: #{release_version_current_internal}. New Internal Build Code: #{build_code_current_internal}"

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
  lane :finalize_hotfix_release do |options|
    ensure_git_branch_is_release_branch

    # Verify that there's nothing in progress in the working copy
    ensure_git_status_clean

    # Pull the latest hotfix release branch changes
    git_pull

    UI.important("Triggering hotfix build for version: #{release_version_current}")
    UI.user_error!('Aborted by user request') unless options[:skip_confirm] || UI.confirm('Do you want to continue?')

    trigger_release_build(branch_to_build: "release/#{release_version_current}")
  end

  # Finalizes a release at the end of a sprint to submit to the App Store
  #
  #  - Updates store metadata
  #  - Bumps final version number
  #  - Removes branch protection and close milestone
  #  - Triggers the final release on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Trigger the final release build on CI'
  lane :finalize_release do |options|
    UI.user_error!('To finalize a hotfix, please use the finalize_hotfix_release lane instead') if ios_current_branch_is_hotfix

    ensure_git_branch_is_release_branch

    # Verify that there's nothing in progress in the working copy
    ensure_git_status_clean

    skip_user_confirmation = options[:skip_confirm]

    UI.important("Finalizing release: #{release_version_current}")
    UI.user_error!('Aborted by user request') unless skip_user_confirmation || UI.confirm('Do you want to continue?')

    git_pull

    check_all_translations(interactive: skip_user_confirmation == false)

    download_localized_strings_and_metadata(options)
    lint_localizations(allow_retry: skip_user_confirmation == false)

    bump_build_codes

    unless skip_user_confirmation || UI.confirm('Ready to push changes to remote and trigger the release build?')
      UI.message("Terminating as requested. Don't forget to run the remainder of this automation manually.")
      next
    end

    push_to_git_remote(tags: false)

    version = release_version_current
    remove_branch_protection(repository: GITHUB_REPO, branch: release_branch_name)
    setfrozentag(repository: GITHUB_REPO, milestone: version, freeze: false)
    create_new_milestone(repository: GITHUB_REPO)
    close_milestone(repository: GITHUB_REPO, milestone: version)

    trigger_release_build

    pr_url = create_release_management_pull_request(
      release_version: release_version_next,
      base_branch: DEFAULT_BRANCH,
      title: "Merge #{version} release finalization"
    )

    message = <<~MESSAGE
      Release successfully finalized. Next, review and merge the [integration PR](#{pr_url}).
    MESSAGE
    buildkite_annotate(context: 'finalization-completed', style: 'success', message:) if is_ci
  end

  # Triggers a beta build on CI
  #
  # @option [String] branch The name of the branch we want the CI to build, e.g. `release/19.3`. Defaults to `release/<current version>`
  #
  lane :trigger_beta_build do |options|
    branch = compute_release_branch_name(options:)
    trigger_buildkite_release_build(branch:, beta: true)
  end

  # Triggers a stable release build on CI
  #
  # @option [String] branch The name of the branch we want the CI to build, e.g. `release/19.3`. Defaults to `release/<current version>`
  #
  lane :trigger_release_build do |options|
    branch = compute_release_branch_name(options:)
    trigger_buildkite_release_build(branch:, beta: false)
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
  buildkite_trigger_build(
    buildkite_organization: BUILDKITE_ORGANIZATION,
    buildkite_pipeline: BUILDKITE_PIPELINE,
    branch:,
    environment: { BETA_RELEASE: beta },
    pipeline_file: 'release-builds.yml',
    message: beta ? 'Beta Builds' : 'Release Builds'
  )
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

def bump_build_codes
  bump_production_build_code
  bump_internal_build_code
  commit_version_and_build_files
end

def bump_production_build_code
  UI.message 'Bumping build code...'
  PUBLIC_VERSION_FILE.write(version_long: build_code_next)
  UI.success "Done. New Build Code: #{build_code_current}"
end

def bump_internal_build_code
  UI.message 'Bumping internal build code...'
  INTERNAL_VERSION_FILE.write(version_long: build_code_next_internal)
  UI.success "Done. New Internal Build Code: #{build_code_current_internal}"
end

def commit_version_and_build_files
  git_commit(
    path: [PUBLIC_CONFIG_FILE, INTERNAL_CONFIG_FILE],
    message: 'Bump version number',
    allow_nothing_to_commit: false
  )
end

def create_release_management_pull_request(release_version:, base_branch:, title:)
  token = ENV.fetch('GITHUB_TOKEN', nil)

  UI.user_error!('Please export a GitHub API token in the environment as GITHUB_TOKEN') if token.nil?

  pr_url = create_pull_request(
    api_token: token,
    repo: 'wordpress-mobile/WordPress-iOS',
    title:,
    head: Fastlane::Helper::GitHelper.current_git_branch,
    base: base_branch,
    labels: 'Releases'
  )

  # Next, set the milestone for the PR
  #
  # The create_pull_request action has a 'milestone' parameter, but it expects the milestone id.
  # We don't know the id of the milestone, but we can use a different action to set it.
  #
  # PR URLs are in the format github.com/org/repo/pull/id
  pr_number = File.basename(pr_url)
  update_pull_requests_milestone(
    repository: GITHUB_REPO,
    pr_numbers: [pr_number],
    to_milestone: release_version
  )

  # Return the PR URL
  pr_url
end
