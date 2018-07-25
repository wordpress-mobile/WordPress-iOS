# A PR should have at least one label
warn("PR is missing at least one label.") if github.pr_labels.empty?

# A PR shouldn't be merged with the 'DO NOT MERGE' label
fail("This PR is tagged with 'DO NOT MERGE'.") if github.pr_labels.include? "[Status] DO NOT MERGE"

# Warn when there is a big PR
warn("PR has more than 500 lines of code changing. Consider splitting into smaller PRs if possible.") if git.lines_of_code > 500

# PRs should have a milestone attached
has_milestone = github.pr_json["milestone"] != nil
warn("PR is not assigned to a milestone.", sticky: false) unless has_milestone

### Core Data Model Safety Checks

target_release_branch = github.branch_for_base.start_with? "release"
has_modified_model = git.modified_files.include? "WordPress/Classes/WordPress.xcdatamodeld/*/contents"

warn("Core Data: Do not edit an existing model in a release branch unless it hasn't been released to testers yet. Instead create a new model version and merge back to develop soon.") if has_modified_model
