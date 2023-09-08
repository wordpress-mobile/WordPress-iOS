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
    - [ ] Create New Site - Skip Quick Start
    - [x] Create New Site - Follow Quick Start (Only checking the first item from the list)
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
    - [ ] View Site from My Site Screen
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
3. With the `WordPress` scheme selected in Xcode, open the Test Navigator and select the `WordPressUITests` test plan.
4. Run the tests on a simulator.

## Adding tests

When adding a new UI test, consider:

* Whether you need to test a user flow (to accomplish a task or goal) or a specific feature (e.g. boundary testing).
* What screens are being tested (defined as page objects in `Screens/`).
* Whether there are repeated flows across tests (defined in `Flows/`).
* What network requests are made during the test (defined in `API-Mocks/`).

It's preferred to focus UI tests on entire user flows, and group tests with related flows or goals in the same test suite.

When you add a new test, you may need to add new screens, methods, and flows. We use page objects and method chaining for clarity in our tests. Wherever possible, use an existing `accessibilityIdentifier` (or add one to the app) instead of a string to select a UI element on the screen. This ensures tests can be run regardless of the device language.

## Adding or updating network mocks

When you add a test (or when the app changes), the request definitions for WireMock need to be updated in `API-Mocks/`. You can read WireMock’s documentation [here](http://wiremock.org/docs/).

If you are unsure what network requests need to be mocked for a test, an easy way to find out is to run the app through [Charles Proxy](https://www.charlesproxy.com/) and observe the required requests.
