import Foundation
import WordPressData

#if UI_TEST_HTTP_FIXTURES
import HTTPFixtures
#endif

struct UITestConfigurator {
    static func prepareApplicationForUITests() {
        if CommandLine.arguments.contains("-ui-test-reset-everything") {
            resetEverything()
        }

        #if UI_TEST_HTTP_FIXTURES
        serveHTTPFixturesIfNeeded()
        #endif
    }

    private static func resetEverything() {
        // Remove CoreData DB
        ContextManager.shared.resetEverything()

        // Clear user defaults.
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    #if UI_TEST_HTTP_FIXTURES
    /// Whether the app is answering its network requests from fixtures.
    static var isServingHTTPFixtures: Bool {
        UserDefaults.standard.string(forKey: "ui-test-http-fixtures") != nil
    }

    /// Answers the app's network requests from the fixtures in the directory passed as the
    /// `-ui-test-http-fixtures` launch argument, so UI tests run against data that doesn't change.
    ///
    /// The `-ui-test-http-log` launch argument names a file to log every request to.
    ///
    /// This has to run before the app creates a `URLSession`. See `FixtureURLProtocol`.
    ///
    /// Only a build that sets the `UI_TEST_HTTP_FIXTURES` compilation condition has this, or the
    /// `HTTPFixtures` module it uses. The build for the UI tests sets it: see `docs/ui-tests.md`.
    private static func serveHTTPFixturesIfNeeded() {
        let defaults = UserDefaults.standard
        guard let directory = defaults.string(forKey: "ui-test-http-fixtures") else {
            return
        }

        do {
            let fixtures = try FixtureSet(directory: URL(filePath: directory))
            let requestLog = defaults.string(forKey: "ui-test-http-log").map { URL(filePath: $0) }
            FixtureURLProtocol.install(fixtures: fixtures, requestLog: requestLog)
        } catch {
            // A test that ran against the network instead would fail in ways that don't point here.
            fatalError("Failed to load the HTTP fixtures in \(directory): \(error)")
        }
    }
    #endif
}
