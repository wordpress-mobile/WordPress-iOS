# frozen_string_literal: true

PIPELINES_ROOT = 'release-pipelines'

platform :ios do
  lane :trigger_code_freeze_in_ci do
    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      # branch: 'trunk', # FIXME: Using current branch while in development
      branch: git_branch,
      pipeline_file: File.join(PIPELINES_ROOT, 'code-freeze.yml'),
      message: 'Code Freeze'
    )
  end

  lane :trigger_complete_code_freeze_in_ci do |options|
    release_version = options[:release_version]

    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      branch: "release/#{release_version}",
      pipeline_file: File.join(PIPELINES_ROOT, 'complete-code-freeze.yml'),
      message: 'Complete Code Freeze',
      environment: { RELEASE_VERSION: release_version }
    )
  end
end
