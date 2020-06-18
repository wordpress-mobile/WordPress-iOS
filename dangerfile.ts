// TODO: would need a check to make sure that we are running from GitHub
// Actions, too
const headRepoName = danger.github.pr.head.repo.full_name
const baseRepoName = danger.github.pr.base.repo.full_name

if headRepoName != baseRepoName {
  // TODO:
  // - Add link to the docs
  // - Maybe there's a way to see if commenting is possible? Maybe this type of
  //   error could be printed only if the comment API returns a 403?
  console.log("\033[1;31m⚠️ Running from a forked repo. Danger won't be able to post comments on the main repo unless GitHub Actions are enabled on the fork, too.\033[0m")
  // I wonder if this sytax works too for colored output and/or reporting?
  console.log("##[warning]⚠️ Running from a forked repo. Danger won't be able to post comments on the main repo unless GitHub Actions are enabled on the fork, too.\033[0m")
}

// I'm not expecting this comment to be posted because the forked repo where
// this Dangerfile lives doesn't have GitHub Actions enabled.
warn("This is a test message.")
