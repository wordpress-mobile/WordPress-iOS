import XCTest

/// Covers how often the app requests an endpoint.
///
/// Only the fixtures backend can count the app's requests. Each test signs in from a reset app,
/// so the counts include everything a sign-in requests.
final class RequestCountTests: JetpackUITestCase {
    override class var backend: Backend { .fixtures }

    func testSigningInFetchesTheAccountAndItsSitesOnce() throws {
        try MySiteScreen(app: app)
            .waitForScreen()

        XCTAssertEqual(try requestCount(path: "/rest/v1.1/me"), 1)
        XCTAssertEqual(try requestCount(path: "/rest/v1.2/me/sites"), 1)
    }
}
