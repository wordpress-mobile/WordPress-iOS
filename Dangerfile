# A PR should have at least one label
warn("PR is missing at least one label.") if github.pr_labels.empty?

# Warn when there is a big PR
warn("PR has more than 500 lines of code changing. Consider splitting into smaller PRs if possible.") if git.lines_of_code > 500

# PRs should have a milestone attached
has_milestone = github.pr_json["milestone"] != nil
warn("PR is not assigned to a milestone.", sticky: false) unless has_milestone

### Core Data Model Safety Checks

target_release_branch = github.branch_for_base.start_with? "release"
has_modified_model = git.modified_files.include? "WordPress/Classes/WordPress.xcdatamodeld/"
has_added_model = git.added_files.include? "WordPress/Classes/WordPress.xcdatamodeld/"

warn("Do not edit an existing model in a release branch; create a new version and merge back to develop soon.") if has_modified_model
warn("Tentacles.") if has_added_model