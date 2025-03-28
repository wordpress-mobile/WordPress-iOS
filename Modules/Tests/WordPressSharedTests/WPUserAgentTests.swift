import Foundation
import Testing
import WebKit
import WordPressShared

class WPWPUserAgentTests {

    @Test
    func userAgentFormat() throws {
        let userAgent = WPUserAgent.defaultUserAgent(userDefaults: .standard)

        #expect(
            try webKitUserAgentRegExp().numberOfMatches(
                in: userAgent,
                options: [],
                range: NSRange(location: 0, length: userAgent.utf16.count)
            ) == 1
        )
    }

    @Test
    func wordPressUserAgentValue() throws {
        let userDefaults = UserDefaults.standard
        let appVersion = try #require(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        let defaultUserAgent = WPUserAgent.defaultUserAgent(userDefaults: userDefaults)
        let expectedUserAgent = String.init(format: "%@ wp-iphone/%@", defaultUserAgent, appVersion)

        #expect(WPUserAgent.wordPressUserAgent(userDefaults: userDefaults) == expectedUserAgent)
    }

    @Test @MainActor
    func usesWordPressUserAgentInWebViews() throws {
        if #available(iOS 17, *) { // #available cannot go as an argument in @Test(.enabled(if: ..))
            print("In iOS 17, WKWebView no longer reads User Agent from UserDefaults. Skipping while working on an alternative setup.")
            return
        }

        let userDefaults = UserDefaults.standard
        let defaultUserAgent = WPUserAgent.defaultUserAgent(userDefaults: userDefaults)
        let wordPressUserAgent = WPUserAgent.wordPressUserAgent(userDefaults: userDefaults)

        // FIXME: Is this necessary?
        // See original implementation at
        // https://github.com/wordpress-mobile/WordPress-iOS/blob/a6eaa7aa8acb50828449df2d3fccaa50d7def821/WordPress/WordPressTest/WPUserAgentTests.m#L57-L75
        userDefaults.removeObject(forKey: WPUserAgent.userAgentKey)
        userDefaults.register(defaults: [WPUserAgent.userAgentKey: defaultUserAgent])

        WPUserAgent.useWordPressInWebViews(userDefaults: userDefaults)

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
                WPUserAgent.wordPressUserAgent(userDefaults: .standard)
            }
        }
    }

    func currentUserAgent(userDefaults: UserDefaults) throws -> String {
        try #require(userDefaults.object(forKey: WPUserAgent.userAgentKey) as? String)
    }

    @MainActor
    func currentUserAgentFromWebView() throws -> String {
        try #require(WKWebView.userAgent())
    }

    func webKitUserAgentRegExp() throws -> NSRegularExpression {
        try NSRegularExpression(
            pattern: "^Mozilla/5\\.0 \\([a-zA-Z]+; CPU [\\sa-zA-Z]+ [_0-9]+ like Mac OS X\\) AppleWebKit/605\\.1\\.15 \\(KHTML, like Gecko\\) Mobile/15E148$"
        )
    }

    // MARK: - Tests for underlying assumptions

    @Test
    func registerInUserDefaultsAdds() throws {
        let userDefaults = UserDefaults.standard
        let domainName = try #require(userDefaults.volatileDomainNames.first)
        let originalDomain = userDefaults.volatileDomain(forName: domainName)

        userDefaults.register(defaults: ["test-key": 0])

        let updatedDomain = userDefaults.volatileDomain(forName: domainName)

        // From the docs:
        // Registered defaults are never stored between runs of an application, and are visible only to the application that registers them
        //
        // So we expect the count to be +1
        #expect(updatedDomain.count == originalDomain.count + 1)
    }

    // If this test fails, it may mean `WKWebView` uses a user agent with an unexpected format (see `webKitUserAgentRegExp`)
    // and we may need to adjust our implementation to match the new `WKWebView` user agent.
    @Test @MainActor
    func testWebKitUserAgentFormat() throws {
        let regExp = try webKitUserAgentRegExp()
        // Please note: WKWebView's user agent may be different on different test device types.
        let userAgent = try currentUserAgentFromWebView()
        #expect(
            try webKitUserAgentRegExp().numberOfMatches(
                in: userAgent,
                options: [],
                range: NSRange(location: 0, length: userAgent.utf16.count)
            ) == 1
        )
    }
}
