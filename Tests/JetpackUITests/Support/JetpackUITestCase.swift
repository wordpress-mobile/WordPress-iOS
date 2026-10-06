import XCTest

/// The base class for Jetpack UI tests.
///
/// Launches the app signed in to WordPress.com with the `-wpcom-token` launch argument, which
/// completes sign-in without any taps, so tests start on My Site.
@MainActor
class JetpackUITestCase: XCTestCase {
    /// Where the app under test gets its data from.
    enum Backend {
        /// WordPress.com, signed in to the account `TestCredentials` has a token for.
        case live
        /// The fixtures in `Tests/JetpackUITests/Fixtures`, which answer every request the app
        /// makes. The account and its sites are always the same, so a test can assert on them.
        case fixtures
    }

    /// Where this suite's tests get their data from.
    class var backend: Backend { .live }

    /// Whether the app's data is wiped before every test.
    ///
    /// A reset app has to sign in again, which syncs the account's sites and takes a while. Suites
    /// whose tests leave the app as they found it can return `false` to share one sign-in across
    /// their tests.
    class var resetsAppBeforeEachTest: Bool { true }

    /// Whether the next test has to start from a reset app even if its suite shares a sign-in:
    /// the first test of the run, and the test after one from a suite that resets, since such a
    /// suite is free to leave the app changed.
    private static var nextTestMustReset = true

    /// The backend the previous test ran against. The two backends sign in to different accounts,
    /// so a test on the other one has to start from a reset app too.
    private static var previousBackend: Backend?

    private(set) var app = XCUIApplication()

    /// What the app has sent in this test, when it runs against the fixtures.
    private(set) var requestLog: RequestLog?

    /// When the app was launched for this test.
    private(set) var launchDate = Date.distantPast

    override func setUp() async throws {
        try await super.setUp()

        // In UI tests it's usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let token: String
        switch Self.backend {
        case .live:
            guard let liveToken = TestCredentials.wpcomToken else {
                throw XCTSkip(
                    "No WordPress.com token. Set TEST_RUNNER_WPCOM_TOKEN or save one to ~/.wpcom-token on the host Mac."
                )
            }
            token = liveToken
        case .fixtures:
            // The fixtures answer the same way whatever the token is.
            token = "fixture-token"
        }

        app.launchArguments = [
            "-wpcom-token", token,
            // A freshly reset app shows its TipKit tips, whose popovers cover the screen under test.
            "-com.apple.TipKit.HideAllTips", "1",
            // After enough activity the app asks whether you're enjoying it, in an alert that can
            // appear over any screen.
            "-AppRatingsSkipRatingCurrentVersion", "YES"
        ]
        if Self.backend == .fixtures {
            let fixtures = try Self.fixturesDirectory
            let requestLog = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).log")
            self.requestLog = RequestLog(file: requestLog)
            // The Simulator doesn't sandbox the app, so it can read the test bundle and write the log.
            app.launchArguments += [
                "-ui-test-http-fixtures", fixtures.path(percentEncoded: false),
                "-ui-test-http-log", requestLog.path(percentEncoded: false)
            ]
        }
        if Self.resetsAppBeforeEachTest || Self.nextTestMustReset || Self.backend != Self.previousBackend {
            app.launchArguments.append("-ui-test-reset-everything")
        }
        Self.nextTestMustReset = Self.resetsAppBeforeEachTest
        Self.previousBackend = Self.backend
        launchDate = Date()
        app.launch()
        try checkAppServesFixtures()
    }

    /// Fails a test on the fixtures backend when the app isn't serving them.
    ///
    /// The fixtures are only in an app built with the `UI_TEST_HTTP_FIXTURES` compilation
    /// condition. Any other build ignores the launch arguments above and sends its requests to
    /// WordPress.com, where the test would fail on whichever screen first needed the fixture
    /// account.
    ///
    /// The app creates the request log as it starts serving the fixtures, before it finishes
    /// launching, so a log that isn't there by now means it isn't serving them.
    private func checkAppServesFixtures() throws {
        guard let requestLog else {
            return
        }
        let deadline = Date(timeIntervalSinceNow: 5)
        while !FileManager.default.fileExists(atPath: requestLog.file.path(percentEncoded: false)) {
            guard Date() < deadline else {
                throw FixturesNotCompiledInError()
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    struct FixturesNotCompiledInError: Error, CustomStringConvertible {
        let description = """
            The app was built without the HTTP fixtures this test runs against. They're only compiled in when the \
            build sets the UI_TEST_HTTP_FIXTURES compilation condition, which a build made in Xcode doesn't. See \
            "Running the tests" in docs/ui-tests.md.
            """
    }

    /// The fixtures the app runs against: the ones in the test bundle, unless the `UI_TEST_FIXTURES`
    /// environment variable names another folder.
    ///
    /// Pointing it at `Tests/JetpackUITests/Fixtures` in the source tree runs the tests against
    /// fixtures as they're being edited, without rebuilding to copy them into the bundle.
    private static var fixturesDirectory: URL {
        get throws {
            if let directory = ProcessInfo.processInfo.environment["UI_TEST_FIXTURES"] {
                return URL(filePath: directory)
            }
            return try XCTUnwrap(
                Bundle(for: JetpackUITestCase.self).url(forResource: "Fixtures", withExtension: nil),
                "The Fixtures folder is missing from the test bundle"
            )
        }
    }

    override func tearDown() async throws {
        // Most failures are an element that wasn't where a screen object expected it, and the
        // hierarchy shows what was there instead.
        if let testRun, testRun.totalFailureCount > 0 {
            let attachment = XCTAttachment(string: app.debugDescription)
            attachment.name = "App hierarchy at failure"
            add(attachment)

            // A screen that didn't load has usually asked for something the fixtures don't have.
            // The log marks those requests "(no fixture)".
            if let requests = try? requestLog?.requests() {
                let attachment = XCTAttachment(string: requests.map(\.description).joined(separator: "\n"))
                attachment.name = "HTTP requests"
                add(attachment)
            }
            if let events = try? sentAnalyticsEvents(), !events.isEmpty {
                let attachment = XCTAttachment(string: events.map(\.description).joined(separator: "\n"))
                attachment.name = "Analytics events"
                add(attachment)
            }
        }

        app.terminate()
        try await super.tearDown()
    }
}
