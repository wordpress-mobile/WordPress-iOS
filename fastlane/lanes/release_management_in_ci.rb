# frozen_string_literal: true

PIPELINES_ROOT = 'release-pipelines'

platform :ios do
  lane :trigger_code_freeze_in_ci do
    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: DEFAULT_BRANCH,
      pipeline_file: File.join(PIPELINES_ROOT, 'code-freeze.yml'),
      message: 'Code Freeze'
    )
  end

  lane :trigger_complete_code_freeze_in_ci do |options|
    release_version_key = :release_version
    release_version = options[release_version_key]

    UI.user_error!("You must specify a release version by calling this lane with a  #{release_version_key} parameter") unless release_version

    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: compute_release_branch_name(options:, version: release_version),
      pipeline_file: File.join(PIPELINES_ROOT, 'complete-code-freeze.yml'),
      message: "Complete Code Freeze for #{release_version}",
      environment: { RELEASE_VERSION: release_version }
    )
  end

  lane :trigger_new_beta_release_in_ci do |options|
    release_version_key = :release_version
    release_version = options[release_version_key]

    UI.user_error!("You must specify a release version by calling this lane with a  #{release_version_key} parameter") unless release_version

    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: compute_release_branch_name(options:, version: release_version),
      pipeline_file: File.join(PIPELINES_ROOT, 'new-beta-release.yml'),
      message: "New Beta Release for #{release_version}",
      environment: { RELEASE_VERSION: release_version }
    )
  end

  lane :trigger_update_app_store_strings_in_ci do |options|
    release_version_key = :release_version
    release_version = options[release_version_key]

    UI.user_error!("You must specify a release version by calling this lane with a  #{release_version_key} parameter") unless release_version

    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: editorial_branch_name(version: release_version),
      pipeline_file: File.join(PIPELINES_ROOT, 'update-app-store-strings.yml'),
      message: "Update Editorialized Release Notes and App Store Metadata for #{release_version}"
    )
  end

  lane :trigger_finalize_release_in_ci do |options|
    release_version_key = :release_version
    release_version = options[release_version_key]

    UI.user_error!("You must specify a release version by calling this lane with a  #{release_version_key} parameter") unless release_version

    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: compute_release_branch_name(options:, version: release_version),
      pipeline_file: File.join(PIPELINES_ROOT, 'finalize-release.yml'),
      message: "Finalize Release #{release_version}",
      environment: { RELEASE_VERSION: release_version }
    )
  end
end
