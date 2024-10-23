#  UI Tests

WordPress for iOS has UI acceptance tests for critical user flows through the app, such as login, signup, and publishing a post. The tests use mocked network requests with [WireMock](http://wiremock.org/), defined in the `API-Mocks` folder in the project's root.

## Test Coverage

The following flows are covered/planned to be covered by UI tests. Tests that are covered will be checked.

1. Unified Login
    - [x] WPCom Account:
        - [x] Log in and log out using WPCom Account
        - [x] Log in and log out Self Hosted Site
        - [x] Invalid Password WPCom Account
        - [x] Add Self Hosted Site after WPCom Login
    - [ ] Apple/Google:
        - [ ] Log in using Apple Account
        - [ ] Log in using Google Account
    - [ ] iCloud Keychain:
        - [ ] Log in using credentials saved in Keychain
    - [ ] Magic Link:
        - [ ] Email Magic Link Login
2. Sign Up:
    - [ ] Email Sign Up - Create New Site
    - [ ] Email Sign Up - Link to Self-Hosted Site
3. NUX
    - [x] Create New Site
    - [ ] Set Up Blogging Reminders on First Post
4. Posting/Editing/Gutenberg
    - [x] Post:
        - [x] Publish Text Post
        - [x] Publish Basic Public Post with Category and Tag
        - [x] Add and Remove Featured Image
        - [x] Add Gallery Block
        - [x] Add Media Blocks (Image, Video and Audio)
        - [x] Create Scheduled Post
    - [ ] Pages:
        - [ ] Create Page from Layout
        - [x] Create Blank Page
5. Notifications
    - [x] View Notification - Comment, Follow and Like Notifications
    - [x] Reply from Notification
    - [x] Like Notification
6. Blogging Reminders
    - [ ] Set Up New Blogging Reminders from Post Publish Prompt
    - [ ] Set Up Scheduled Story Post (iPhone Only)
7. Stats
    - [x] Insights Stats Load Properly
    - [x] Years Stats Load Properly
8. Reader
    - [x] View Last Post
    - [x] View Last Post in Safari
    - [x] Add Comment to Post
    - [x] Follow New Topic on Discover Tab
    - [x] Save a Post
    - [x] Like a Post
9. Jetpack Settings
    - [ ] Open and View Jetpack Settings Options
    - [ ] Search and View a Plugin
10. View Site
    - [x] View Site from My Site Screen
    - [ ] Update Site and Validate Changes
11. Dashboard (Jetpack Only)
    - [x] Free to Paid Plans Card
    - [x] Pages Card Header Navigation
    - [x] Activity Log Card Header Navigation
12. Navigation
    - [x] Load People Screen
    - [x] Tab Bar Navigation (Reader and Notification tabs)
    - [x] Domains Navigation (Jetpack Only)
13. Support Screen/Help
    - [ ] Support Forums Loaded during Login
    - [x] Contact Us Loaded during Login

## Running tests

Note that due to the mock server setup, tests cannot be run on physical devices right now.

1. Follow the [build instructions](https://github.com/wordpress-mobile/WordPress-iOS#build-instructions) (steps 1-5) to clone the project, install the dependencies, and open the project in Xcode.
2. `rake mocks` to start a local mock server.
3. With the `Jetpack` scheme selected in Xcode, open the Test Navigator and select the `JetpackUITests` test plan.
4. Run the tests on a simulator.

## Adding tests

When adding a new UI test, consider:

* Whether to test a user flow (to accomplish a task or goal) or a specific feature (e.g. boundary testing).
* What screens are being tested (defined as screen objects in [Screens](https://github.com/wordpress-mobile/WordPress-iOS/tree/trunk/WordPress/UITestsFoundation/Screens)).
* Are there repeated flows across tests (defined in [Flows](https://github.com/wordpress-mobile/WordPress-iOS/tree/trunk/WordPress/UITests/Flows)).
* What network requests are made during the test (defined in [API-Mocks](https://github.com/wordpress-mobile/WordPress-iOS/tree/trunk/API-Mocks)).

Tests classes are grouped together in [Tests](https://github.com/wordpress-mobile/WordPress-iOS/tree/trunk/WordPress/UITests/Tests)

When you add a new test, you may need to add new screens, methods, and flows. We use page objects and method chaining for clarity in our tests. Wherever possible, use an existing `accessibilityIdentifier` (or add one to the app) instead of a string to select a UI element on the screen. This ensures tests can be run regardless of the device language.

## Design Guidelines

### Naming convention

* Use unique names with namespaces for accessibility identifiers, e.g. `sidebar_reader` to make it easy to find elements with a single query. 
* When creating new tests, use the `testActionFeature` format for the test name to make it easier to see what the test is for: e.g. `testCreateScheduledPost()`
* When creating new methods, use the `actionObject` format: e.g. `closePostSettings()`
* For assert methods, use the `verifyWhatToVerify` format: e.g. `verifyPostExists()`
* Note that there’s a common global method `assertScreenIsLoaded()` that can be used to assert all screens

### Performance

- Use [`firstMatch`](https://developer.apple.com/documentation/xctest/xcuielementtypequeryprovider/2902250-firstmatch) in queries when you expect only one element to be visible. It's a ~10x improvement (but it's not as important in absolute numbers)
- Reduce the number of queries. It's about 20-50% faster to find an element by a unique accessibility identifier with a single query to first find its parent and then the element.  
- Consolidate related tests into a single test to eliminate the unnecessary app startups that take a large portion of test time

## Mocking

### Adding or updating network mocks

When you add a test (or when the app changes), the request definitions for WireMock need to be updated in `API-Mocks/`. You can read WireMock’s documentation [here](http://wiremock.org/docs/).

If you are unsure what network requests need to be mocked for a test, an easy way to find out is to run the app through [Proxyman](https://proxyman.io/) or [Charles Proxy](https://www.charlesproxy.com/) and observe the required requests.

Currently, the project does not apply strict mock matching criteria, this means that if there are unmatched requests that are not being used by the test itself. The test should still work although errors like this can be seen in the logs:

<img width="1000" alt="unmatched request" src="https://github.com/wordpress-mobile/WordPress-iOS/assets/17252150/2e6595b1-6fdd-4255-9721-90c278518d75">

When adding a new test however, it is recommended that all requests are matched so that the logs are not further cluttered with `Request was not matched` like in the above screenshot.

### Using stateful behavior for mocks

1. Add the new scenario in [scenarios.json](https://github.com//wordpress-mobile/WordPress-iOS/tree/trunk/API-Mocks/WordPressMocks/src/main/assets/mocks/__files/__admin/scenarios.json)
2. Fetch and reset scenario during `SetUp()` in the test class containing the test, e.g. seen on [Notification Test](https://github.com/wordpress-mobile/WordPress-iOS/blob/5730cee6568fe43fb3a5108e396e12244c62b3e5/WordPress/UITests/Tests/NotificationTests.swift#L18-L23)
3. Update JSON mappings to contain the following 3 new attributes, `scenarioName`, `requiredScenarioState` and `newScenarioState`, and the response matching the state of the scenario, e.g. seen on [Notification Test](https://github.com/wordpress-mobile/WordPress-iOS/blob/5730cee6568fe43fb3a5108e396e12244c62b3e5/API-Mocks/WordPressMocks/src/main/assets/mocks/mappings/wpcom/notifications/notifications_comment_reply_before.json#L2-L4)

### Tips and tricks on using mocks
* When getting the same request with the same header but a different request body to return different responses, experiment with using [different matchers](https://docs.wiremock.io/request-matching/matcher-types/). From some experimenting, I would recommend using `matchesJsonPath` which is used to differentiate [Create Page](https://github.com/wordpress-mobile/WordPress-iOS/blob/5a00e849d8877e8ae2a6ec6bc9c762e68e6e0620/API-Mocks/WordPressMocks/src/main/assets/mocks/mappings/wpcom/pages/sites_106707880_pages_new.json#L18) and [Create Post](https://github.com/wordpress-mobile/WordPress-iOS/blob/5a00e849d8877e8ae2a6ec6bc9c762e68e6e0620/API-Mocks/WordPressMocks/src/main/assets/mocks/mappings/wpcom/posts/posts_new.json#L18).
* Use `verbose` to debug errors, this can be updated by adding the `verbose` parameter when [starting the WireMock server](https://github.com/wordpress-mobile/WordPress-iOS/blob/5a00e849d8877e8ae2a6ec6bc9c762e68e6e0620/API-Mocks/scripts/start.sh#L20-L23) (don’t forget the slash to not break the command).
* If there are no errors on the console, but the mocks don’t work as expected, check out the app’s logs for errors. Sometimes it could be that the JSON mapping is not parsed correctly.
