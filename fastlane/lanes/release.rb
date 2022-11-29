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
    gutenberg_dep_check
    ios_codefreeze_prechecks(options)

    ios_bump_version_release(skip_deliver: true, skip_glotpress: true)
    new_version = ios_get_app_version

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
    ios_update_release_notes(new_version: new_version)

    setbranchprotection(repository: GHHELPER_REPO, branch: "release/#{new_version}")
    setfrozentag(repository: GHHELPER_REPO, milestone: new_version)
    ios_check_beta_deps(podfile: File.join(PROJECT_ROOT_FOLDER, 'Podfile'))

    print_release_notes_reminder
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
    ios_completecodefreeze_prechecks(options)
    generate_strings_file_for_glotpress

    if prompt_for_confirmation(
      message: 'Ready to push changes to remote and trigger the beta build?',
      bypass: ENV.fetch('RELEASE_TOOLKIT_SKIP_PUSH_CONFIRM', nil)
    )
      push_to_git_remote(tags: false)
      trigger_beta_build
    else
      UI.message('Aborting code freeze completion. See you later.')
    end
  end

  # Creates a new beta by bumping the app version appropriately then triggering a beta build on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  # @option [String] base_version (default: _current app version_) If set, bases the beta on the specified version
  #                  and `release/<base_version>` branch instead of the current one. Useful for triggering betas on hotfixes for example.
  #
  desc 'Trigger a new beta build on CI'
  lane :new_beta_release do |options|
    ios_betabuild_prechecks(options)
    download_localized_strings_and_metadata(options)
    ios_lint_localizations(input_dir: 'WordPress/Resources', allow_retry: true)
    ios_bump_version_beta
    trigger_beta_build
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
    prev_ver = ios_hotfix_prechecks(options)
    ios_bump_version_hotfix(
      previous_version: prev_ver,
      version: options[:version],
      skip_deliver: true
    )
  end

  # Finalizes a hotfix, by triggering a release build on CI
  #
  # @option [Boolean] skip_confirm (default: false) If true, avoids any interactive prompt
  #
  desc 'Performs the final checks and triggers a release build for the hotfix in the current branch'
  lane :finalize_hotfix_release do |options|
    ios_finalize_prechecks(options)
    git_pull
    trigger_release_build
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

    ios_finalize_prechecks(options)
    git_pull

    check_all_translations(interactive: true)

    download_localized_strings_and_metadata(options)
    ios_lint_localizations(input_dir: 'WordPress/Resources', allow_retry: true)
    ios_bump_version_beta

    # Wrap up
    version = ios_get_app_version
    removebranchprotection(repository: GHHELPER_REPO, branch: release_branch_name)
    setfrozentag(repository: GHHELPER_REPO, milestone: version, freeze: false)
    create_new_milestone(repository: GHHELPER_REPO)
    close_milestone(repository: GHHELPER_REPO, milestone: version)

    trigger_release_build
  end

  # Triggers a beta build on CI
  #
  # @option [String] branch The name of the branch we want the CI to build, e.g. `release/19.3`. Defaults to `release/<current version>`
  #
  lane :trigger_beta_build do |options|
    branch = options[:branch] || release_branch_name
    trigger_buildkite_release_build(branch: branch, beta: true)
  end

  # Triggers a stable release build on CI
  #
  # @option [String] branch The name of the branch we want the CI to build, e.g. `release/19.3`. Defaults to `release/<current version>`
  #
  lane :trigger_release_build do |options|
    branch = options[:branch] || release_branch_name
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
  buildkite_trigger_build(
    buildkite_organization: 'automattic',
    buildkite_pipeline: 'wordpress-ios',
    branch: branch,
    environment: { BETA_RELEASE: beta },
    pipeline_file: 'release-builds.yml',
    message: beta ? 'Beta Builds' : 'Release Builds'
  )
end

# Checks that the Gutenberg pod is reference by a tag and not a commit
#
desc 'Verifies that Gutenberg is referenced by release version and not by commit'
lane :gutenberg_dep_check do
  res = ''

  File.open File.join(PROJECT_ROOT_FOLDER, 'Podfile') do |file|
    res = file.find { |line| line =~ /^(?!\s*#)(?=.*\bgutenberg\b).*(\bcommit|tag\b){1}.+/ }
  end

  UI.user_error!("Can't find any reference to Gutenberg!") if res.empty?
  if res.include?('commit')
    UI.user_error!("Gutenberg referenced by commit!\n#{res}") unless UI.interactive?

    unless UI.confirm("Gutenberg referenced by commit!\n#{res}\nDo you want to continue anyway?")
      UI.user_error!('Aborted by user request. Please fix Gutenberg reference and try again.')
    end
  end

  UI.message("Gutenberg version: #{res.scan(/'([^']*)'/)[0][0]}")
end

# Returns the path to the extracted Release Notes file for the given `app`.
#
# @param [String|Symbol] app The app to get the path for, must be one of `wordpress` or `jetpack`
#
def extracted_release_notes_file_path(app:)
  paths = {
    wordpress: File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Resources', 'release_notes.txt'),
    jetpack: File.join(PROJECT_ROOT_FOLDER, 'WordPress', 'Jetpack', 'Resources', 'release_notes.txt')
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

def release_branch_name
  "release/#{ios_get_app_version}"
end
