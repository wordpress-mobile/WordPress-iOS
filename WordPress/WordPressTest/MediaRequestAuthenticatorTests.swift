import XCTest
@testable import WordPress

class MediaRequestAuthenticatorTests: XCTestCase {

    func testPublicSiteAuthentication() {
        let url = URL(string: "http://www.wordpress.com")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .publicSite,
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: { $0.key == "Authorization" }) ?? false

                XCTAssertFalse(hasAuthorizationHeader)
                XCTAssertEqual(request.url, url)
        }) { error in
            XCTFail("This should not be called")
        }
    }

    func testPublicWPComSiteAuthentication() {
        let url = URL(string: "http://www.wordpress.com")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .publicSite,
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: { $0.key == "Authorization" }) ?? false

                XCTAssertFalse(hasAuthorizationHeader)
                XCTAssertEqual(request.url, url)
        }) { error in
            XCTFail("This should not be called")
        }
    }

    /// This test only checks that the resulting URL is the origina URL for now.  There's no special authentication
    /// logic within `MediaRequestAuthenticator` for this case.
    ///
    /// - TODO: consider bringing self-hosted private authentication logic into MediaRequestAuthenticator.
    ///
    func testPrivateSelfHostedSiteAuthentication() {
        let url = URL(string: "http://www.wordpress.com")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .publicSite,
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: { $0.key == "Authorization" }) ?? false

                XCTAssertFalse(hasAuthorizationHeader)
                XCTAssertEqual(request.url, url)
        }) { error in
            XCTFail("This should not be called")
        }
    }

    func testPrivateWPComSiteAuthentication() {
        let authToken = "letMeIn!"
        let url = URL(string: "http://www.wordpress.com")!
        let expectedURL = URL(string: "https://www.wordpress.com")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .privateWPComSite(authToken: authToken),
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: {
                    $0.key == "Authorization" && $0.value == "Bearer \(authToken)"
                }) ?? false

                XCTAssertTrue(hasAuthorizationHeader)
                XCTAssertEqual(request.url, expectedURL)
        }) { error in
            XCTFail("This should not be called")
        }
    }

    func testPrivateAtomicWPComSiteAuthentication() {
        let username = "demouser"
        let authToken = "letMeIn!"
        let siteID = 15567
        let url = URL(string: "http://www.wordpress.com")!
        let expectedURL = URL(string: "https://www.wordpress.com")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .privateAtomicWPComSite(siteID: siteID, username: username, authToken: authToken),
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: {
                    $0.key == "Authorization" && $0.value == "Bearer \(authToken)"
                }) ?? false

                XCTAssertTrue(hasAuthorizationHeader)
                XCTAssertEqual(request.url, expectedURL)
        }) { error in
            XCTFail("This should not be called")
        }
    }
}
