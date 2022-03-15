# frozen_string_literal: true

platform :ios do
  #####################################################################################
  # code_freeze
  # -----------------------------------------------------------------------------------
  # This lane executes the initial steps planned on code freeze
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane code_freeze [skip_confirm:<skip confirm>]
  #
  # Example:
  # bundle exec fastlane code_freeze
  # bundle exec fastlane code_freeze skip_confirm:true
  #####################################################################################
  desc 'Creates a new release branch from the current trunk'
  lane :code_freeze do |options|
    gutenberg_dep_check
    ios_codefreeze_prechecks(options)

    ios_bump_version_release(skip_deliver: true)
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

  #####################################################################################
  # complete_code_freeze
  # -----------------------------------------------------------------------------------
  # This lane executes the initial steps planned on code freeze
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane complete_code_freeze [skip_confirm:<skip confirm>]
  #
  # Example:
  # bundle exec fastlane complete_code_freeze
  # bundle exec fastlane complete_code_freeze skip_confirm:true
  #####################################################################################
  desc 'Creates a new release branch from the current trunk'
  lane :complete_code_freeze do |options|
    ios_completecodefreeze_prechecks(options)
    generate_strings_file_for_glotpress

    UI.confirm('Ready to push changes to remote and trigger the beta build?') unless ENV['RELEASE_TOOLKIT_SKIP_PUSH_CONFIRM']
    push_to_git_remote(tags: false)
    trigger_beta_build(branch_to_build: "release/#{ios_get_app_version}")
  end

  #####################################################################################
  # new_beta_release
  # -----------------------------------------------------------------------------------
  # This lane updates the release branch for a new beta release. It will update the
  # current release branch by default. If you want to update a different branch
  # (i.e. hotfix branch) pass the related version with the 'base_version' param
  # (example: base_version:10.6.1 will work on the 10.6.1 branch)
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane new_beta_release [skip_confirm:<skip confirm>] [base_version:<version>]
  #
  # Example:
  # bundle exec fastlane new_beta_release
  # bundle exec fastlane new_beta_release skip_confirm:true
  # bundle exec fastlane new_beta_release base_version:10.6.1
  #####################################################################################
  desc 'Updates a release branch for a new beta release'
  lane :new_beta_release do |options|
    ios_betabuild_prechecks(options)
    download_localized_strings_and_metadata(options)
    # FIXME: (2021.06.17) This is disabled because we currently have a >256 chars string which GlotPress truncates when exporting  the `.strings` files,
    #   leading to incorrect key for it and (rightful) linter failure. We need to split that key into 2 smaller copies before we can re-enable this.
    # ios_lint_localizations(input_dir: 'WordPress/Resources', allow_retry: true)
    ios_bump_version_beta
    version = ios_get_app_version
    trigger_beta_build(branch_to_build: "release/#{version}")
  end

  #####################################################################################
  # new_hotfix_release
  # -----------------------------------------------------------------------------------
  # This lane updates the release branch for a new hotfix release.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane new_hotfix_release [skip_confirm:<skip confirm>] [version:<x.y.z>]
  #
  # Example:
  # bundle exec fastlane new_hotfix_release version:10.6.1
  #####################################################################################
  desc 'Creates a new hotfix branch for the given version:x.y.z. The branch will be cut from the tag x.y of the previous release'
  lane :new_hotfix_release do |options|
    prev_ver = ios_hotfix_prechecks(options)
    ios_bump_version_hotfix(
      previous_version: prev_ver,
      version: options[:version],
      skip_deliver: true
    )
  end

  #####################################################################################
  # finalize_hotfix_release
  # -----------------------------------------------------------------------------------
  # This lane finalizes the hotfix branch.
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane finalize_hotfix_release [skip_confirm:<skip confirm>]
  #
  # Example:
  # bundle exec fastlane finalize_hotfix_release skip_confirm:true
  #####################################################################################
  desc 'Performs the final checks and triggers a release build for the hotfix in the current branch'
  lane :finalize_hotfix_release do |options|
    ios_finalize_prechecks(options)
    version = ios_get_app_version
    trigger_release_build(branch_to_build: "release/#{version}")
  end


  #####################################################################################
  # finalize_release
  # -----------------------------------------------------------------------------------
  # This lane finalize a release: updates store metadata, bump final version number,
  # remove branch protection and close milestone, then trigger the final release on CI
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane finalize_release [skip_confirm:<skip confirm>] [version:<version>]
  #
  # Example:
  # bundle exec fastlane finalize_release
  # bundle exec fastlane finalize_release skip_confirm:true
  #####################################################################################
  desc 'Trigger the final release build on CI'
  lane :finalize_release do |options|
    UI.user_error!('To finalize a hotfix, please use the finalize_hotfix_release lane instead') if ios_current_branch_is_hotfix

    ios_finalize_prechecks(options)

    check_all_translations(interactive: true)

    download_localized_strings_and_metadata(options)
    # FIXME: (2021.06.17) This is disabled because we currently have a >256 chars string which GlotPress truncates when exporting  the `.strings` files,
    #   leading to incorrect key for it and (rightful) linter failure. We need to split that key into 2 smaller copies before we can re-enable this.
    # ios_lint_localizations(input_dir: 'WordPress/Resources', allow_retry: true)
    ios_bump_version_beta

    # Wrap up
    version = ios_get_app_version
    removebranchprotection(repository: GHHELPER_REPO, branch: "release/#{version}")
    setfrozentag(repository: GHHELPER_REPO, milestone: version, freeze: false)
    create_new_milestone(repository: GHHELPER_REPO)
    close_milestone(repository: GHHELPER_REPO, milestone: version)

    # Start the build
    trigger_release_build(branch_to_build: "release/#{version}")
  end


  #####################################################################################
  # trigger_beta_build
  # -----------------------------------------------------------------------------------
  # This lane triggers a beta build on CI
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane trigger_beta_build [branch_to_build:<branch_name>]
  #
  #####################################################################################
  lane :trigger_beta_build do |options|
    trigger_buildkite_release_build(branch: options[:branch_to_build], beta: true)
  end

  #####################################################################################
  # trigger_release_build
  # -----------------------------------------------------------------------------------
  # This lane triggers a stable release build on CI
  # -----------------------------------------------------------------------------------
  # Usage:
  # bundle exec fastlane trigger_release_build [branch_to_build:<branch_name>]
  #
  #####################################################################################
  lane :trigger_release_build do |options|
    trigger_buildkite_release_build(branch: options[:branch_to_build], beta: false)
  end
end



def trigger_buildkite_release_build(branch:, beta:)
  buildkite_trigger_build(
    buildkite_organization: 'automattic',
    buildkite_pipeline: 'wordpress-ios',
    branch: branch,
    environment: { BETA_RELEASE: beta },
    pipeline_file: 'release-builds.yml'
  )
end

desc 'Verifies that Gutenberg is referenced by release version and not by commit'
lane :gutenberg_dep_check do |_options|
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

  UI.message("Gutenberg version: #{(res.scan(/'([^']*)'/))[0][0]}")
end
