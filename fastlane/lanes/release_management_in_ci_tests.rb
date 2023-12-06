# frozen_string_literal: true

platform :ios do
  lane :test_code_freeze_automation do
    push_to_git_remote(tags: false) # the local automation lane should do this

    create_release_management_pull_request(base_branch: 'trunk', title: 'Test automated code freeze PR')
  end
end
