# How to Contribute

First off, thank you for contributing! We're excited to collaborate with you! 🎉

The following is a set of guidelines for the many ways you can join our collective effort.

Before anything else, please take a moment to read our [Code of Conduct](CODE-OF-CONDUCT.md). We expect all participants, from full-timers to occasional tinkerers, to uphold it.

## Reporting Bugs, Asking Questions, and Suggesting Features

Have a suggestion or feedback? Please go to [Issues](https://github.com/wordpress-mobile/WordPress-iOS/issues) and [open a new issue](https://github.com/wordpress-mobile/WordPress-iOS/issues/new). Prefix the title with a category like _"Bug:"_, _"Question:"_, or _"Feature Request:"_. Screenshots help us resolve issues and answer questions faster, so thanks for including some if you can.

## Translating

We use GlotPress to manage translations. Please go to the [WordPress for iOS GlotPress page](https://translate.wordpress.org/projects/apps/ios/dev/) for more information on how to add or edit translations.

## Beta Testing

Interested in using the upcoming versions of WordPress? Do you love giving feedback on new features and don't mind reporting bugs that come up along the way? Join us in the beta-testing program by going to the [WordPress for iOS TestFlight program](https://testflight.apple.com/join/AkJQt8Pw) page using your iOS device and follow the instructions. 

## Submitting Code Changes

If you're just getting started and want to familiarize yourself with the app’s code, we suggest looking at [these issues](https://github.com/wordpress-mobile/WordPress-iOS/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) with the **good first issue** label. But if you’d like to tackle something different, you're more than welcome to visit the [Issues](https://github.com/wordpress-mobile/WordPress-iOS/issues) page and pick an item that interests you.

We always try to avoid duplicating efforts, so if you decide to work on an issue, leave a comment to state your intent. If you choose to focus on a new feature or the change you’re proposing is significant, we recommend waiting for a response before proceeding. The issue may no longer align with project goals.

If the change is trivial, feel free to send a pull request without notifying us.

### Before Opening a Pull Request

CI does not run on pull requests from forks, so a maintainer is the first person to build your change. Before you open a pull request:

1. Build your change and run the tests for the code you changed. This needs macOS and Xcode.
2. Run each affected test suite with this command. If you don't have an `iPhone 18 Pro` simulator, use any iPhone simulator listed by `xcrun simctl list devices available`.

    ```bash
    xcodebuild -workspace WordPress.xcworkspace -scheme WordPress -testPlan WordPressUnitTests -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test -only-testing:<TestTarget>/<Suite>
    ```

    For example, `-only-testing:WordPressTest/RemoteFeatureFlagTests`. Repeat `-only-testing:` once for each suite.
3. If you're opening the pull request from a fork, add a "What I ran" section to the description. List the test suites you ran and paste the result line each one printed. XCTest prints a line like `Executed 3 tests, with 0 failures`. Swift Testing prints a line like `Test run with 6 tests in 1 suite passed`. If your change has no tests to run (for example, a documentation change), write `No tests apply:` followed by the reason.
4. If you could not build the change or run its tests (for example, because you aren't on macOS), don't open a pull request. Comment on the issue with your proposed approach instead.

You are responsible for every line in your pull request, including code written by an AI tool. Build it and run it yourself before you submit it.

### Pull Requests and Code Reviews

All code contributions pass through pull requests. If you haven't created a pull request before, we recommend this free video series, [How to Contribute to an Open Source Project on GitHub](https://egghead.io/courses/how-to-contribute-to-an-open-source-project-on-github).

The core team monitors and reviews all pull requests. Depending on the changes, we will either approve them or close them with an explanation. We might also work with you to improve a pull request before approval.

We do our best to respond quickly to all pull requests. If you don't get a response from us after a week, feel free to reach out to us via Slack.

Note: If you are part of the org and have the permissions on the repo, don't forget to assign yourself to the PR, and add the appropriate GitHub label and Milestone for the PR

### PR merge policy

* PRs require one reviewer to approve the PR before it can be merged to the base branch
* We keep the PR git history when merging (merge via "merge commit")
* Who merges the PR once it's approved and green?
  * For PRs authored by people external to the organisation and not having push permissions, the reviewer who approved the PR will merge it.
  * For PRs authored by contributors with push permissions, the author of the PR will merge their own PR.

## Getting in Touch

If you have questions or just want to say hi, join the [WordPress Slack](https://make.wordpress.org/chat/) and drop a message on the `#mobile` channel.
