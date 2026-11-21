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

        XCTAssertEqual(try accountRequestCount(), 1)
        XCTAssertEqual(try requestCount(path: "/rest/v1.2/me/sites"), 1)
    }

    /// Counts the app's requests for the account from `/me`.
    ///
    /// The Notifications bell also requests `/me`, for its `has_unseen_notes` field alone, so a
    /// request that asks for only some `fields` isn't counted.
    private func accountRequestCount() throws -> Int {
        guard let requestLog else {
            throw RequestLogUnavailableError()
        }
        return try requestLog.requests()
            .filter { request in
                let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
                return request.method == "GET"
                    && request.url.host() == "public-api.wordpress.com"
                    && request.url.path() == "/rest/v1.1/me"
                    && components?.queryItems?.contains { $0.name == "fields" } != true
            }
            .count
    }
}
