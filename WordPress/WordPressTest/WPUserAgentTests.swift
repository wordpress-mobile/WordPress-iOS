import Testing
import WebKit
@testable import WordPress

class WPWPUserAgentTests {

    @Test
    func wordPressUserAgentValue() throws {
        let userDefaults = UserDefaults.standard
        let appVersion = try #require(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        let defaultUserAgent = TemporaryWPUserAgent.defaultUserAgent(userDefaults: userDefaults)
        let expectedUserAgent = String.init(format: "%@ wp-iphone/%@", defaultUserAgent, appVersion)

        #expect(TemporaryWPUserAgent.wordPressUserAgent(userDefaults: userDefaults) == expectedUserAgent)
    }

    @Test
    func usesWordPressUserAgentInWebViews() throws {
        if #available(iOS 17, *) { // #available cannot go as an argument in @Test(.enabled(if: ..))
            print("In iOS 17, WKWebView no longer reads User Agent from UserDefaults. Skipping while working on an alternative setup.")
            return
        }

        let userDefaults = UserDefaults.standard
        let defaultUserAgent = TemporaryWPUserAgent.defaultUserAgent(userDefaults: userDefaults)
        let wordPressUserAgent = TemporaryWPUserAgent.wordPressUserAgent(userDefaults: userDefaults)

        // FIXME: Is this necessary?
        // See original implementation at
        // https://github.com/wordpress-mobile/WordPress-iOS/blob/a6eaa7aa8acb50828449df2d3fccaa50d7def821/WordPress/WordPressTest/WPUserAgentTests.m#L57-L75
        userDefaults.removeObject(forKey: TemporaryWPUserAgent.userAgentKey)
        userDefaults.register(defaults: [TemporaryWPUserAgent.userAgentKey: defaultUserAgent])

        WPUserAgent.useWordPressInWebViews()

        #expect(try currentUserAgent(userDefaults: userDefaults) == wordPressUserAgent)
        #expect(try currentUserAgentFromWebView() == wordPressUserAgent)
    }

    // FIXME: Is there even a point in testing for no throws when the method does not throw?
    // See original implementation at
    // https://github.com/wordpress-mobile/WordPress-iOS/blob/a6eaa7aa8acb50828449df2d3fccaa50d7def821/WordPress/WordPressTest/WPUserAgentTests.m#L102-L107
    @Test
    func accessingWordPressUserAgentOutsideMainThread() {
        #expect(throws: Never.self, "Accessing outside the main thread should work") {
            DispatchQueue.global(qos: .background).sync {
                TemporaryWPUserAgent.wordPressUserAgent(userDefaults: .standard)
            }
        }
    }

    func currentUserAgent(userDefaults: UserDefaults) throws -> String {
        try #require(userDefaults.object(forKey: TemporaryWPUserAgent.userAgentKey) as? String)
    }

    func currentUserAgentFromWebView() throws -> String {
        try #require(WKWebView.userAgent())
    }
}
