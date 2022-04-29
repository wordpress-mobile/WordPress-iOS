import OHHTTPStubs
import UIKit
import XCTest
@testable import WordPress

class AtomicAuthenticationServiceTests: XCTestCase {
    var contextManager: TestContextManager!
    var atomicService: AtomicAuthenticationService!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        contextManager.requiresTestExpectation = false

        let api = WordPressComRestApi(oAuthToken: "")
        let remote = AtomicAuthenticationServiceRemote(wordPressComRestApi: api)
        atomicService = AtomicAuthenticationService(remote: remote)
    }

    override func tearDown() {
        super.tearDown()

        ContextManager.overrideSharedInstance(nil)
        contextManager.mainContext.reset()
        contextManager = nil
        atomicService = nil
    }

    fileprivate func stubResponse(forEndpoint endpoint: String, responseFilename filename: String) {
        stub(condition: { request in
            return (request.url!.absoluteString as NSString).contains(endpoint) && request.httpMethod! == "GET"
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type": "application/json"])
        }
    }

    func testGetAuthCookie() {
        let siteID = 55115566
        let endpoint = "sites/\(siteID)/atomic-auth-proxy/read-access-cookies"
        let successExpectation = expectation(description: "We expect the cookie to be retrieved and decoded fine.")

        stubResponse(forEndpoint: endpoint, responseFilename: "atomic-get-authentication-cookie-success.json")

        atomicService.getAuthCookie(siteID: siteID, success: { cookie in
            XCTAssertEqual(cookie.name, "wordpress_logged_in_39d5e8179c238764ac288442f27d091b")

            if cookie.name == "wordpress_logged_in_39d5e8179c238764ac288442f27d091b"
                && cookie.value == "johndoe|1544455667|KwKSrAKJsqIWCTtt2QImT3hFTgHuzDOaMprlWWZXQeQ|7f0a75827e7f72ce645ec817ac9a2ab58735e95752494494cc463d1ad5853add"
                && cookie.domain == "testingblog.wordpress.com"
                && cookie.path == "/"
                && cookie.expiresDate == Date(timeIntervalSince1970: 1584511597) {

                successExpectation.fulfill()
            }
        }) { _ in
            XCTFail("Can't get the requested auth cookie.")
        }

        waitForExpectations(timeout: TimeInterval(0.1))
    }
}
