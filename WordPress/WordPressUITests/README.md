#  UI Tests

WordPress for iOS has UI acceptance tests for critical user flows through the app, such as login, signup, and publishing a post. The tests use mocked network requests with [WireMock](http://wiremock.org/), defined in [WordPressMocks](https://github.com/wordpress-mobile/WordPressMocks).

## Running tests

Note that due to the mock server setup, tests cannot be run on physical devices right now.

1. Follow the [build instructions](https://github.com/wordpress-mobile/WordPress-iOS#build-instructions) (steps 1-5) to clone the project, install the dependencies, and open the project in Xcode.
2. `rake mocks` to start a local mock server.
3. With the `WordPress` scheme selected in Xcode, open the Test Navigator and select the `WordPressUITests` test plan.
4. Run the tests on a simulator.

## Adding tests

When adding a new UI test, consider:

* Whether you need to test a user flow (to accomplish a task or goal) or a specific feature (e.g. boundary testing).
* What screens are being tested (defined as page objects in `Screens/`).
* Whether there are repeated flows across tests (defined in `Flows/`).
* What network requests are made during the test (defined in the `WordPressMocks` repo).

It's preferred to focus UI tests on entire user flows, and group tests with related flows or goals in the same test suite.

When you add a new test, you may need to add new screens, methods, and flows. We use page objects and method chaining for clarity in our tests. Wherever possible, use an existing `accessibilityIdentifier` (or add one to the app) instead of a string to select a UI element on the screen. This ensures tests can be run regardless of the device language.

## Adding or updating network mocks

When you add a test (or when the app changes), the request definitions for WireMock need to be updated. You can read WireMock’s documentation [here](http://wiremock.org/docs/).

If you are unsure what network requests need to be mocked for a test, an easy way to find out is to run the app through [Charles Proxy](https://www.charlesproxy.com/) and observe the required requests.

Since `WordPressMocks` is included as a pod in `WordPress-iOS`, you can update your `Podfile` to point to your local version and make changes there. Submit a pull request to the `WordPressMocks` repo so a new version of the pod can be released with those changes.
