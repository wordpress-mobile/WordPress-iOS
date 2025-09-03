import XCTest
@testable import WordPressKit

class AtomicAuthenticationServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Data

    let testSiteID = 2020

    // MARK: - Endpoints

    let getAuthCookieEndpoint = "sites/2020/atomic-auth-proxy/read-access-cookies"

    // MARK: - Mock Response Filenames

    let getAuthCookieSuccessMockFilename = "atomic-get-auth-cookie-success.json"

    func testGetAuthCookie() {
        let remote = AtomicAuthenticationServiceRemote(wordPressComRestApi: getRestApi())
        let expectation = self.expectation(description: "We should get the requested auth cookie.")

        stubRemoteResponse(getAuthCookieEndpoint, filename: getAuthCookieSuccessMockFilename, contentType: .ApplicationJSON)

        remote.getAuthCookie(siteID: testSiteID, success: { cookie in
            XCTAssertEqual(cookie.name, "name")
            XCTAssertEqual(cookie.value, "value")
            XCTAssertEqual(cookie.domain, "someblog.wordpress.com")
            XCTAssertEqual(cookie.path, "/")
            XCTAssertEqual(cookie.expiresDate, Date(timeIntervalSince1970: TimeInterval(1583364400)))

            expectation.fulfill()
        }, failure: { error in
            XCTFail("❗️ Test failure: \(error)")
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
