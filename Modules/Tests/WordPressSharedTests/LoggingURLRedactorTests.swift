import Foundation
import Testing
@testable import WordPressShared

struct LoggingURLRedactorTests {

    @Test func testThatMagicLoginTokenURLsAreRedacted() {
        let wpInternalMagicTokenURL = URL(string: "wpinternal://magic-login?foo=bar&token=foo")!
        let wpInternalRedactedURL = URL(string: "wpinternal://magic-login?foo=bar&token=redacted")!
        #expect(wpInternalRedactedURL == LoggingURLRedactor.redactedURL(wpInternalMagicTokenURL))

        let magicTokenURL = URL(string: "wordpress://magic-login?foo=bar&token=foo")!
        let redactedURL = URL(string: "wordpress://magic-login?foo=bar&token=redacted")!
        #expect(redactedURL == LoggingURLRedactor.redactedURL(magicTokenURL))

        let debugMagicTokenURL = URL(string: "wpdebug://magic-login?foo=bar&token=foo")!
        let debugRedactedURL = URL(string: "wpdebug://magic-login?foo=bar&token=redacted")!
        #expect(debugRedactedURL == LoggingURLRedactor.redactedURL(debugMagicTokenURL))

        let alphaMagicTokenURL = URL(string: "wpalpha://magic-login?foo=bar&token=foo")!
        let alphaRedactedURL = URL(string: "wpalpha://magic-login?foo=bar&token=redacted")!
        #expect(alphaRedactedURL == LoggingURLRedactor.redactedURL(alphaMagicTokenURL))
    }

    @Test func testThatSafeURLsAreNotRedacted() {
        let safeURL = URL(string: "https://foo.com/bar?token=baz")!
        #expect(safeURL == LoggingURLRedactor.redactedURL(safeURL))
    }
}
