# frozen_string_literal: true

def release_branch?
  danger.github.branch_for_base.start_with?('release/') || danger.github.branch_for_base.start_with?('hotfix/')
end

def main_branch?
  danger.github.branch_for_base == 'trunk'
end

def wip_feature?
  has_wip_label = github.pr_labels.any? { |label| label.include?('WIP') }
  has_wip_title = github.pr_title.include?('WIP')

  has_wip_label || has_wip_title
end

return if github.pr_labels.include?('Releases')

github.dismiss_out_of_range_messages

manifest_pr_checker.check_all_manifest_lock_updated

labels_checker.check(
  do_not_merge_labels: ['[Status] DO NOT MERGE'],
  required_labels: [//],
  required_labels_error: 'PR requires at least one label.'
)

view_changes_need_screenshots.view_changes_need_screenshots

pr_size_checker.check_diff_size

# skip check for draft PRs and for WIP features unless the PR is against the main branch or release branch
milestone_checker.check_milestone_due_date(days_before_due: 4) unless github.pr_draft? || (wip_feature? && !(release_branch? || main_branch?))

rubocop.lint(inline_comment: true, fail_on_inline_comment: true, include_cop_names: true)

swiftlint.config_file = '.swiftlint.yml'
swiftlint.binary_path = './Pods/SwiftLint/swiftlint'
swiftlint.lint_files inline_mode: true
