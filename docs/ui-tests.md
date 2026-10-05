# UI Tests

The `JetpackUITests` target holds the XCUITest UI tests for the Jetpack app. Most suites drive a real app build signed in to a real WordPress.com account, so they need a WordPress.com bearer token to run. A suite can instead run against [fixtures](#fixtures), which needs no token.

## Running the tests

The tests sign in with the same token as `make sim-login` (see [Simulator Sign-In](simulator-sign-in.md)): the `WPCOM_TOKEN` environment variable, then `~/.wpcom-token` on the Mac. Without a token, every test that needs one is skipped rather than failed.

In Xcode, select the **Jetpack** scheme and a Simulator destination, then run the tests from the Test Navigator. `JetpackUITests` is the scheme's default test plan.

From the command line:

```bash
xcodebuild \
  -workspace WordPress.xcworkspace \
  -scheme Jetpack \
  -testPlan JetpackUITests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  test
```

`xcodebuild` doesn't pass its own environment to the test runner, but it forwards any variable prefixed with `TEST_RUNNER_` with the prefix removed. To supply the token from the environment instead of `~/.wpcom-token`, export it as `TEST_RUNNER_WPCOM_TOKEN`.

The tests only run on a Simulator, because the token file is read from the Mac's home directory.

## Structure

```
Tests/JetpackUITests
├── JetpackUITests.xctestplan
├── Screens   # One screen object per screen or component
├── Support   # The test case and screen object base classes, credentials
└── Tests     # The test cases
```

The folder is synchronized with the `JetpackUITests` target, so a new file is picked up without editing the project file.

## Writing a test

Subclass `JetpackUITestCase`. Its `setUp` launches a freshly reset app signed in to WordPress.com, so every test starts on My Site.

Resetting means signing in again, which syncs the account's sites and adds around 20 seconds to a test. A suite whose tests leave the app as they found it can override `resetsAppBeforeEachTest` to return `false`: its tests then relaunch the app still signed in. The app is still reset before the first test of the run, and before the first test that follows a suite that resets, since such a suite is free to leave the app changed.

Keep the default for a suite that changes anything the app stores on the device. `StatsCustomizationTests` does, for example: it switches chart metrics, data types and date ranges, and adds and removes cards, all of which the app remembers.

Tests are written against screen objects rather than element queries. A screen object exposes the elements and actions for one screen, and each navigation method returns the screen it navigates to:

```swift
final class EditorTests: JetpackUITestCase {
    func testOpenAndDiscardNewPost() throws {
        try MySiteScreen(app: app)
            .goToNewPost()
            .closeAndDiscardChanges()
    }
}
```

To add a screen, subclass `ScreenObject` and pass it the elements that identify the screen. Initializing a screen object waits for the first of those elements to become hittable and throws if it doesn't, so constructing one doubles as the assertion that the app reached that screen.

Identify elements by accessibility identifier where the app sets one. Several screens don't have one yet; their screen objects fall back to the navigation bar title, which works because the test plan pins the app's language to English.

Because the tests run against a real account, a test must leave the account as it found it — discard drafts instead of publishing them, and undo any setting it changes.

## What the tests check, and what they don't

The suites that run against a real account check that each screen, menu and sheet opens, and that controls change state: a filter becomes selected, a date range changes, a card moves. They don't check content. Nothing in them asserts a post's title, a stat's value or the site's name, so they aren't tied to one account. Asserting on content is what the [fixtures](#fixtures) are for.

They do need the account's site to have something to open, and what a site has changes over time: activity ages out of the activity log, and a quiet week has no referrers. A test whose card isn't on the dashboard, or whose list has nothing in it, is skipped with a message saying what was missing rather than failed. A skip therefore means "this site couldn't exercise that path today", so read the skipped tests in a run as well as the failures.

When a test fails, its attachments include the app's accessibility hierarchy at the moment of failure.

## Fixtures

A suite can run against a fixed set of data instead of a real account by overriding `backend`:

```swift
final class FixtureAccountTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }

    func testMySiteShowsThePrimarySite() throws {
        let mySite = try MySiteScreen(app: app)

        XCTAssertEqual(mySite.siteTitle.label, "Tri-County Real Estate")
    }
}
```

The app then answers every request it makes from the files in `Tests/JetpackUITests/Fixtures`, and nothing reaches WordPress.com. Such a suite needs no token, can assert on content, and has no account to leave as it found it.

The fixtures describe one account, `e2eflowtestingmobile`, with three sites: Tri-County Real Estate (the primary site, on the Personal plan), Four Paws Dog Grooming (Free) and Weekend Bakes (Pro). They're the WireMock mappings that the UI tests removed in #25399 ran against, restored from before #25673 deleted them, so they predate some of what the app requests today. See [Finding what's missing](#finding-whats-missing).

The two backends sign in to different accounts, so the app is also reset before a test that runs on a different backend from the test before it.

Use the fixtures for any screen that changes the account just by being looked at. Showing the Notifications tab marks the account's notifications as seen, opening a notification marks it as read, and opening a post in the Reader counts as a view of it and can mark it as seen. `NotificationsTests` and `ReaderTests` run on the fixtures for that reason, and `MeTests` does so that it can assert on the account's details.

### How it works

`JetpackUITestCase` passes the app the path of the fixtures in the `-ui-test-http-fixtures` launch argument. The app loads them into a `FixtureSet` and puts `FixtureURLProtocol` in front of every `URLSession`; both are in the `HTTPFixtures` module. That's below the app's API clients, so one mechanism covers them all: WordPressKit, Alamofire and wordpress-rs each send their requests through a `URLSession`.

It doesn't cover requests that leave the app's process another way: the content of a web view, which includes the block editor's own requests, background uploads, the notifications WebSocket and media playback. Those still go to the network, where the fixture account's token is no good.

`FixtureURLProtocol` is compiled into debug builds only.

### Writing a fixture

Each file under `Fixtures/mappings` is a [WireMock stub mapping](https://wiremock.org/docs/stubbing/): a request matcher and the response to answer with.

```json
{
  "request": {
    "method": "GET",
    "urlPath": "/rest/v1.1/sites/106707880/posts",
    "queryParameters": {
      "status": { "equalTo": "draft,pending" }
    }
  },
  "response": {
    "status": 200,
    "jsonBody": { "found": 0, "posts": [] }
  }
}
```

A mapping matches on the method, path, query and body of a request, and never on its host, so the same files answer for `public-api.wordpress.com`, a site's own address and anything else the app talks to.

Only the parts of the format the fixtures use are supported:

- **Request**: `method`; one of `url`, `urlPath`, `urlPattern` and `urlPathPattern`; `queryParameters` with `equalTo`, `matches` or `absent`; `bodyPatterns` with `equalTo`, `matches`, `equalToJson` or `matchesJsonPath`.
- **Response**: `status`, `headers`, `body` or `jsonBody`, and `fixedDelayMilliseconds`.
- **Templates** in a response, such as `{{request.requestLine.baseUrl}}` and `{{now offset='-3 days' format='yyyy-MM-dd'}}`. `ResponseTemplate` lists them all. Use `{{now}}` for any date the app compares with today, such as the days of a stats chart.
- **Scenarios** (`scenarioName`, `requiredScenarioState` and `newScenarioState`), which let one request change what a later one gets, so that a post appears in the posts list once it's been published.
- **The `stats-series` transformer**, for a response with a row for every period in the interval the request asks for. See [Stats](#stats).

A mapping that uses anything else fails to load, and the app won't launch with fixtures it can't load. The `HTTPFixturesTests` unit tests load the same files, so they report the problem without launching the app.

The fixtures are copied into the test bundle when it's built. To try a change without rebuilding, point the tests at the source folder with the `UI_TEST_FIXTURES` environment variable, which `xcodebuild` forwards as `TEST_RUNNER_UI_TEST_FIXTURES`:

```bash
TEST_RUNNER_UI_TEST_FIXTURES="$PWD/Tests/JetpackUITests/Fixtures" xcodebuild \
  -workspace WordPress.xcworkspace \
  -scheme Jetpack \
  -testPlan JetpackUITests \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:JetpackUITests/StatsFixtureTests \
  test-without-building
```

When more than one mapping matches a request, the one with the lowest `priority` answers; the default is 5. Between mappings of equal priority, the one with more query, body and scenario conditions answers, and after that the first by file path. Give overlapping mappings a `priority` rather than relying on their paths.

### Stats

The fixtures answer everything the Stats screens ask for, on all three tabs, for every kind of top list and for every date range. `StatsFixtureTests` walks those screens and fails if a request went unanswered or if Stats reported that a card failed to load, which is what a fixture with the wrong shape causes. Run it after changing a stats fixture, or when the app starts asking Stats for something new.

Most stats responses are the same whatever dates are asked for, so a top list shows the same posts and counts for today as for the year. The counts are sized for the last seven days, which is the range Stats opens on.

Views, visitors and the other numbers charted over time can't work that way. The app asks for an interval, such as the last seven days by day, or today by hour, and charts every row it gets back, so the response has to have exactly the rows for that interval. Those come from the `stats-series` transformer, which generates them from a description of each field:

```json
{
  "request": {
    "method": "GET",
    "urlPathPattern": "/rest/v1.1/sites/[0-9]+/stats/visits/*"
  },
  "response": {
    "status": 200,
    "transformers": ["stats-series"],
    "transformerParameters": {
      "fields": [
        { "name": "views", "average": 432, "hourly": true },
        { "name": "visitors", "average": 268 }
      ]
    }
  }
}
```

- `average` is what the field comes to on an average day. Each day's value varies around it, lower at weekends, and is computed from the date alone, so a day has the same value in every chart and on every run.
- `level` is for a running total, such as subscribers: its value today, which was lower by `growth` for every day before.
- `hourly` says whether the field has values by the hour. The others are null then, as they are from WordPress.com.

### Analytics

A suite on the fixtures backend can assert on the analytics events the app sends. The app's requests to Tracks are answered by a fixture like any other request, and the test reads the events out of them, so what it sees is what Tracks would have received:

```swift
func testOpeningStatsFromAQuickActionIsTracked() throws {
    try MySiteScreen(app: app)
        .goToStats()
        .waitForScreen()

    let event = try waitForAnalyticsEvent("jpios_stats_accessed")
    XCTAssertEqual(event.properties["tap_source"], "quick_actions")
}
```

An event's name is the one Tracks receives, with the app's `jpios_` prefix. `waitForAnalyticsEvent` also takes properties the event has to have, which is how to pick one event out of several with the same name, and `sentAnalyticsEvents()` returns everything sent so far, for a test that needs to check an order or that an event wasn't sent.

The app queues the events it tracks and sends them every 15 seconds, so `waitForAnalyticsEvent` can take that long to return. It waits 30 seconds by default.

Only the events the app tracked since it launched for the test are returned. The app also sends events an earlier launch tracked and didn't get to send, and those are left out.

This isn't available against a real account, where the events go to Tracks.

### Request counts

A suite on the fixtures backend can count the app's requests, to check that it doesn't ask for the same thing more often than it should:

```swift
func testSigningInFetchesTheAccountAndItsSitesOnce() throws {
    try MySiteScreen(app: app)
        .waitForScreen()

    XCTAssertEqual(try requestCount(path: "/rest/v1.1/me"), 1)
    XCTAssertEqual(try requestCount(path: "/rest/v1.2/me/sites"), 1)
}
```

Requests are counted by endpoint: a method, a host and a path. The query isn't part of it, so requests for different pages or dates of the same thing count towards one endpoint. `requestCount` means `GET` and `public-api.wordpress.com` unless told otherwise. `requestCounts()` returns the count for every endpoint, and `assertNoEndpointRequested(moreThan:)` fails with a list of the endpoints the app has requested more often than a limit.

The counts start when the app launches for the test, so a suite that shares one sign-in across its tests doesn't count what signing in requests. A count is of the requests made so far, and the app goes on making requests after a screen appears, so a count read as soon as a screen appears can miss a repeat that comes later.

A count includes the requests the fixtures didn't answer. The app gets an error for those, which can change how often it asks, so check that an endpoint has a fixture before reading much into its count.

### Finding what's missing

A request no mapping matches gets a 404, which the app handles like any failed request: a card stays empty, or a screen shows its error state.

A test can list them with `unansweredRequests()`. `StatsFixtureTests` does, to fail when Stats asks for something the fixtures don't have.

When a test on the fixtures backend fails, its attachments include **Analytics events**, which lists the events the app sent, and **HTTP requests**, which lists every request the app made and the mapping that answered it. The ones that need a fixture end in `(no fixture)`:

```
200 GET https://public-api.wordpress.com/rest/v1.1/me?locale=en wpcom/me/me.json
404 GET https://public-api.wordpress.com/wpcom/v2/mobile/remote-config?locale=en (no fixture)
```
