WordPress iOS releases are handled following the [Git Flow](http://nvie.com/posts/a-successful-git-branching-model/) model for Git with most release cycles lasting 2 weeks.

## Standard Release

A description of what happens during a standard release taking as an example version `9.1` of the app.

### Day 1 (Monday): CODE FREEZE

- Create a new branch from develop called `release/9.1`: only features completed before Day 1 will make it to the release.
- Generate the English strings file on this branch, this will pick up all the new strings that were added since the last release.
- Mark the milestone as frozen.
- Protect the branch to avoid unwanted merges.
- Release the beta version and post the call for testing on [Make WordPress Mobile](https://make.wordpress.org/mobile/).
- Merge back to develop.
- A script will automatically pick up new strings and upload them to GlotPress for translation.

### Day 2-13: STABILIZATION

- If we discover any bugs on `release/9.1` that were introduced on the last sprint, important crashes, or bugs in new features to be released, we submit a PR targeting `release/9.1`, and we make a new beta release. We then merge back to develop.

### Day 14: SUBMISSION & RELEASE

- Fetch the localized strings from GlotPress and integrate them into the project.
- Generate a production build and upload it to the store and phase release it.
- Finalize the release on GitHub and close the milestone.
- Merge `release/9.1` into `develop` and into `master`.

## Hot Fix

Sometimes there is a bug or crash that can’t wait two weeks to be fixed. This is how we handle this, for example when a critical issue is uncovered on version `9.1` of the app, currently released.

- Create a new branch from master called `release/9.1.1`.
- Create a PR against that branch.
- Get approvals, test very very very well, merge.
- Submit to the store.
- Merge back into `develop` and into `master`.
