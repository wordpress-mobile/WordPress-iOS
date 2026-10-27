## Description
<!-- Describe the changes, why they are needed, and how they address the issue -->

## What I ran
<!--

CI does not run on pull requests from forks, so a maintainer is the first person to build your change. Before you open a pull request:

1. Build your change and run the tests for the code you changed. This needs macOS and Xcode.
2. Run each affected test suite with this command. If you don't have an `iPhone 18 Pro` simulator, use any iPhone simulator listed by `xcrun simctl list devices available`.

    ```bash
    xcodebuild -workspace WordPress.xcworkspace -scheme WordPress -testPlan WordPressUnitTests -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test -only-testing:<TestTarget>/<Suite>
    ```

    For example, `-only-testing:WordPressTest/RemoteFeatureFlagTests`. Repeat `-only-testing:` once for each suite.
3. In the pull request description, include the exact command and the test result lines it printed. XCTest prints a line like `Executed 3 tests, with 0 failures`. Swift Testing prints a line like `Test run with 6 tests in 1 suite passed`.
4. If you could not build the change or run its tests (for example, because you aren't on macOS), don't open a pull request. Comment on the issue with your proposed approach instead.

-->

- [ ] I built this change and ran the affected tests locally

## Testing instructions
<!-- Consider listing specific testing steps for helping reviewers evaluate the efficacy of the changes -->

<!--

Consider testing the following *yourself* before requesting a review:

- Compatibility with WordPress.com sites and self-hosted Jetpack sites
- Both portrait and landscape orientations
- Light and dark modes
- Dynamic font sizes: larger, smaller and bold text
- High contrast mode
- Screen reader experience (e.g., VoiceOver)
- Languages with large words or with letters/accents not frequently used in English
- Right-to-left languages layout
- Multi-tasking: split view and slide over

-->
