@testable import WordPressAuthenticator
import XCTest

class GoogleClientIdTests: XCTestCase {

    func testFailsInitIfNotAValidFormat() {
       XCTAssertNil(GoogleClientId(string: "invalid"))
    }

    func testDoesNotFailInitIfValidFormat() {
        XCTAssertNotNil(GoogleClientId(string: "com.something.something"))
        XCTAssertNotNil(GoogleClientId(string: "a.b.c"))
    }

    func testRedirectURIGeneration() {
        XCTAssertEqual(GoogleClientId(string: "a.b.c")?.redirectURI(path: .none), "c.b.a")
        XCTAssertEqual(GoogleClientId(string: "a.b.c")?.redirectURI(path: "a_path"), "c.b.a:/a_path")
    }

    func testDefaultRedirectURI() {
        XCTAssertEqual(GoogleClientId(string: "a.b.c")?.defaultRedirectURI, "c.b.a:/oauth2callback")
    }
}
