import XCTest
import OHHTTPStubs
@testable import WordPress

class MediaRequestAuthenticatorTests: XCTestCase {
    fileprivate var contextManager: TestContextManager!
    fileprivate var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = contextManager.mainContext
    }

    override func tearDown() {
        contextManager  =  nil
        context = nil

        super.tearDown()
    }

    // MARK: - Utility

    func setupAccount(username: String, authToken: String) {
        let account = ModelTestHelper.insertAccount(context: context)
        account.uuid = UUID().uuidString
        account.userID = NSNumber(value: 156)
        account.username = username
        account.authToken = authToken
        contextManager.saveContextAndWait(context)
        AccountService(managedObjectContext: context).setDefaultWordPressComAccount(account)
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
        }) { error in
            XCTFail("This should not be called")
        }

        waitForExpectations(timeout: 0.05)
    }
}
