import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import WordPress
@testable import WordPressData

class MediaRequestAuthenticatorTests: CoreDataTestCase {
    override func setUp() {
        super.setUp()

        contextManager.useAsSharedInstance(untilTestFinished: self)
    }

    // MARK: - Utility

    func setupAccount(username: String, authToken: String) {
        let account = ModelTestHelper.insertAccount(context: mainContext)
        account.uuid = UUID().uuidString
        account.userID = NSNumber(value: 156)
        account.username = username
        account.authToken = authToken
        contextManager.saveContextAndWait(mainContext)
        AccountService(coreDataStack: contextManager).setDefaultWordPressComAccount(account)
    }

    fileprivate func stubResponse(forEndpoint endpoint: String, responseFilename filename: String) {
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains(endpoint) && request.httpMethod! == "GET"
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "application/json"])
        }
    }

    // MARK: - Tests

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
        }) { _ in
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
        }) { _ in
            XCTFail("This should not be called")
        }
    }

    /// This test only checks that the resulting URL is the original URL for now. There's no special authentication
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
        }) { _ in
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
        }) { _ in
            XCTFail("This should not be called")
        }
    }

    func testPrivateAtomicWPComSiteAuthentication() {
        let username = "demouser"
        let authToken = "letMeIn!"
        let siteID = 15567
        let url = URL(string: "http://www.wordpress.com")!
        let expectedURL = URL(string: "https://www.wordpress.com")!
        let expectation = self.expectation(description: "Completion closure called")

        setupAccount(username: username, authToken: authToken)

        let endpoint = "sites/\(siteID)/atomic-auth-proxy/read-access-cookies"
        stubResponse(forEndpoint: endpoint, responseFilename: "atomic-get-authentication-cookie-success.json")

        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .privateAtomicWPComSite(siteID: siteID, username: username, authToken: authToken),
            onComplete: { request in
                expectation.fulfill()

                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: {
                    $0.key == "Authorization" && $0.value == "Bearer \(authToken)"
                }) ?? false

                XCTAssertTrue(hasAuthorizationHeader)
                XCTAssertEqual(request.url, expectedURL)
        }) { _ in
            XCTFail("This should not be called")
        }

        waitForExpectations(timeout: 0.5)
    }

    func testPrivateWPComSiteAuthenticationDoesNotLeakTokenToExternalHost() {
        let authToken = "letMeIn!"
        let url = URL(string: "https://attacker.example.com/image.png")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .privateWPComSite(authToken: authToken),
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: { $0.key == "Authorization" }) ?? false

                XCTAssertFalse(hasAuthorizationHeader)
                XCTAssertEqual(request.url, url)
        }) { _ in
            XCTFail("This should not be called")
        }
    }

    func testPrivateWPComSiteAuthenticationDoesNotLeakTokenToLookalikeHost() {
        let authToken = "letMeIn!"
        let url = URL(string: "https://evilwordpress.com/image.png")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .privateWPComSite(authToken: authToken),
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: { $0.key == "Authorization" }) ?? false

                XCTAssertFalse(hasAuthorizationHeader)
                XCTAssertEqual(request.url, url)
        }) { _ in
            XCTFail("This should not be called")
        }
    }

    func testPrivateWPComSiteAuthenticationForPhotonURL() {
        let authToken = "letMeIn!"
        let url = URL(string: "https://i0.wp.com/example.files.wordpress.com/image.png")!
        let authenticator = MediaRequestAuthenticator()

        authenticator.authenticatedRequest(
            for: url,
            from: .privateWPComSite(authToken: authToken),
            onComplete: { request in
                let hasAuthorizationHeader = request.allHTTPHeaderFields?.contains(where: {
                    $0.key == "Authorization" && $0.value == "Bearer \(authToken)"
                }) ?? false

                XCTAssertTrue(hasAuthorizationHeader)
                XCTAssertEqual(request.url, url)
        }) { _ in
            XCTFail("This should not be called")
        }
    }

    /// `AVURLAsset` does not expose its options dictionary, so the tests use the URL as the
    /// observable: the authenticated branch upgrades http to https, the unauthenticated
    /// branch leaves the URL untouched. `testTokenAllowedHosts` covers the allowlist itself.
    func testPrivateWPComSiteAssetForExternalHostIsNotAuthenticated() async throws {
        let authenticator = MediaRequestAuthenticator()
        let url = URL(string: "http://attacker.example.com/video.mp4")!

        let asset = try await authenticator.authenticatedAsset(for: url, host: .privateWPComSite(authToken: "letMeIn!"))

        XCTAssertEqual(asset.url, url)
    }

    func testPrivateWPComSiteAssetForWPComHostIsAuthenticated() async throws {
        let authenticator = MediaRequestAuthenticator()
        let url = URL(string: "http://example.files.wordpress.com/video.mp4")!

        let asset = try await authenticator.authenticatedAsset(for: url, host: .privateWPComSite(authToken: "letMeIn!"))

        XCTAssertEqual(asset.url, URL(string: "https://example.files.wordpress.com/video.mp4")!)
    }
}
