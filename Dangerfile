# A PR should have at least one label
fail "Please add labels to this PR" if github.pr_labels.empty?

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

# PRs should have a milestone attached
has_milestone = github.pr_json["milestone"] != nil
warn("This PR does not refer to an existing milestone", sticky: false) unless has_milestone
