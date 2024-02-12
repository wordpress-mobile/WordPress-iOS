# frozen_string_literal: true

github.dismiss_out_of_range_messages

# `files: []` forces rubocop to scan all files, not just the ones modified in the PR
rubocop.lint(files: [], force_exclusion: true, inline_comment: true, fail_on_inline_comment: true, include_cop_names: true)

manifest_pr_checker.check_all_manifest_lock_updated

podfile_checker.check_podfile_does_not_have_branch_references

ios_release_checker.check_core_data_model_changed
ios_release_checker.check_release_notes_and_app_store_strings

# skip remaining checks if we're during the release process
if github.pr_labels.include?('Releases')
  message('This PR has the `Releases` label: some checks will be skipped.')
  return
end

common_release_checker.check_internal_release_notes_changed(report_type: :message)

ios_release_checker.check_modified_translations_on_release_branch

view_changes_checker.check

pr_size_checker.check_diff_size(max_size: 500)

# skip remaining checks if we have a Draft PR
return if github.pr_draft?

labels_checker.check(
  do_not_merge_labels: ['[Status] DO NOT MERGE'],
  required_labels: [//],
  required_labels_error: 'PR requires at least one label.'
)

# skip check for WIP features unless the PR is against the main branch or release branch
milestone_checker.check_milestone_due_date(days_before_due: 4) unless github_utils.wip_feature? && !(github_utils.release_branch? || github_utils.main_branch?)
