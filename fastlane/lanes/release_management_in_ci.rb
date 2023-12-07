# frozen_string_literal: true

platform :ios do
  lane :trigger_code_freeze_in_ci do
    buildkite_trigger_build(
      buildkite_organization: BUILDKITE_ORGANIZATION,
      buildkite_pipeline: BUILDKITE_PIPELINE,
      # branch: 'trunk', # FIXME: Using current branch while in development
      branch: git_branch,
      pipeline_file: 'release-pipelines/code-freeze.yml',
      message: 'Code Freeze'
    )
  end
end
