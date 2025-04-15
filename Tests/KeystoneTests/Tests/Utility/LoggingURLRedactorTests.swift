import XCTest
@testable import WordPress

class LoggingURLRedactorTests: XCTestCase {

    func testThatMagicLoginTokenURLsAreRedacted() {
        let wpInternalMagicTokenURL = URL(string: "wpinternal://magic-login?foo=bar&token=foo")!
        let wpInternalRedactedURL = URL(string: "wpinternal://magic-login?foo=bar&token=redacted")!
        XCTAssertEqual(wpInternalRedactedURL, LoggingURLRedactor.redactedURL(wpInternalMagicTokenURL))

        let magicTokenURL = URL(string: "wordpress://magic-login?foo=bar&token=foo")!
        let redactedURL = URL(string: "wordpress://magic-login?foo=bar&token=redacted")!
        XCTAssertEqual(redactedURL, LoggingURLRedactor.redactedURL(magicTokenURL))

        let debugMagicTokenURL = URL(string: "wpdebug://magic-login?foo=bar&token=foo")!
        let debugRedactedURL = URL(string: "wpdebug://magic-login?foo=bar&token=redacted")!
        XCTAssertEqual(debugRedactedURL, LoggingURLRedactor.redactedURL(debugMagicTokenURL))

        let alphaMagicTokenURL = URL(string: "wpalpha://magic-login?foo=bar&token=foo")!
        let alphaRedactedURL = URL(string: "wpalpha://magic-login?foo=bar&token=redacted")!
        XCTAssertEqual(alphaRedactedURL, LoggingURLRedactor.redactedURL(alphaMagicTokenURL))
    }

    func testThatSafeURLsAreNotRedacted() {
        let safeURL = URL(string: "https://foo.com/bar?token=baz")!
        XCTAssertEqual(safeURL, LoggingURLRedactor.redactedURL(safeURL))
    }
}
