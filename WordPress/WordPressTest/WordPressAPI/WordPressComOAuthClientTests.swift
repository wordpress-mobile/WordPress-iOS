import XCTest
import WordPress
import OHHTTPStubs

class WordPressOAuthClientTests: XCTestCase {

    let WordPressComOAuthTokenUrl = "https://public-api.wordpress.com/oauth2/token"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    func testAuthenticateUsernameNo2FASuccessCase() {
        OHHTTPStubs.stubRequestsPassingTest({(request) -> Bool in
            return request.URL?.absoluteString == self.WordPressComOAuthTokenUrl
            }, withStubResponse:{ (request:NSURLRequest) -> OHHTTPStubsResponse in
                let mockDataURL = NSBundle(forClass: self.dynamicType).URLForResource("WordPressOAuthClientSuccess", withExtension:"json")!
                let mockData = NSData(contentsOfURL: mockDataURL)!
                let stubResponse = OHHTTPStubsResponse(data: mockData, statusCode:200, headers:["Content-Type":"application/json"])
                stubResponse.responseTime = OHHTTPStubsDownloadSpeedWifi;
                return stubResponse
        })

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let client = WordPressComOAuthClient()
        client.authenticateWithUsername("fakeUser", password: "fakePass", multifactorCode: nil, success: { (token) in
            expectation.fulfill()
            XCTAssert(!token.isEmpty, "There should be a token available")
            XCTAssert(token == "fakeToken", "There should be a token available")
            }, failure: { (error) in
                expectation.fulfill()
                XCTFail("This call should be successfull")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testAuthenticateUsernameNo2FAFailureWrongPasswordCase() {
        OHHTTPStubs.stubRequestsPassingTest({(request) -> Bool in
            return request.URL?.absoluteString == self.WordPressComOAuthTokenUrl
            }, withStubResponse:{ (request:NSURLRequest) -> OHHTTPStubsResponse in
                let mockDataURL = NSBundle(forClass: self.dynamicType).URLForResource("WordPressOAuthClientWrongPasswordFail", withExtension:"json")!
                let mockData = NSData(contentsOfURL: mockDataURL)!
                let stubResponse = OHHTTPStubsResponse(data: mockData, statusCode:400, headers:["Content-Type":"application/json"])
                stubResponse.responseTime = OHHTTPStubsDownloadSpeedWifi;
                return stubResponse
        })

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let client = WordPressComOAuthClient()
        client.authenticateWithUsername("fakeUser", password: "wrongPassword", multifactorCode: nil, success: { (token) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error) in
                expectation.fulfill()
                XCTAssert(error.domain == WordPressComOAuthErrorDomain, "The error should an WordPressComOAuthError")
                XCTAssert(error.code == Int(WordPressComOAuthError.InvalidRequest.rawValue), "The code should be invalid request")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testAuthenticateUsername2FAWrong2FACase() {
        OHHTTPStubs.stubRequestsPassingTest({(request) -> Bool in
            return request.URL?.absoluteString == self.WordPressComOAuthTokenUrl
            }, withStubResponse:{ (request:NSURLRequest) -> OHHTTPStubsResponse in
                let mockDataURL = NSBundle(forClass: self.dynamicType).URLForResource("WordPressOAuthClientNeed2FAFail", withExtension:"json")!
                let mockData = NSData(contentsOfURL: mockDataURL)!
                let stubResponse = OHHTTPStubsResponse(data: mockData, statusCode:400, headers:["Content-Type":"application/json"])
                stubResponse.responseTime = OHHTTPStubsDownloadSpeedWifi;
                return stubResponse
        })

        let expectation = self.expectationWithDescription("Call should complete")
        let client = WordPressComOAuthClient()
        client.authenticateWithUsername("fakeUser", password: "wrongPassword", multifactorCode: nil, success: { (token) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error) in
                expectation.fulfill()
                XCTAssert(error.domain == WordPressComOAuthErrorDomain, "The error should an WordPressComOAuthError")
                XCTAssert(error.code == Int(WordPressComOAuthError.NeedsMultifactorCode.rawValue), "The code should be needs multifactor")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)

        let expectation2 = self.expectationWithDescription("Call should complete")
        client.authenticateWithUsername("fakeUser", password: "fakePassword", multifactorCode: "fakeMultifactor", success: { (token) in
            expectation2.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error) in
                expectation2.fulfill()
                XCTAssert(error.domain == WordPressComOAuthErrorDomain, "The error should an WordPressComOAuthError")
                XCTAssert(error.code == Int(WordPressComOAuthError.NeedsMultifactorCode.rawValue), "The code should be needs multifactor")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testrequestOneTimeCodeWithUsername() {
        OHHTTPStubs.stubRequestsPassingTest({(request) -> Bool in
            return request.URL?.absoluteString == self.WordPressComOAuthTokenUrl
            }, withStubResponse:{ (request:NSURLRequest) -> OHHTTPStubsResponse in
                let mockDataURL = NSBundle(forClass: self.dynamicType).URLForResource("WordPressOAuthClientNeed2FAFail", withExtension:"json")!
                let mockData = NSData(contentsOfURL: mockDataURL)!
                let stubResponse = OHHTTPStubsResponse(data: mockData, statusCode:400, headers:["Content-Type":"application/json"])
                stubResponse.responseTime = OHHTTPStubsDownloadSpeedWifi;
                return stubResponse
        })

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let client = WordPressComOAuthClient()
        client.requestOneTimeCodeWithUsername("fakeUser", password: "fakePassword",
                                              success: { () in
                                                expectation.fulfill()
            }, failure: { (error) in
                expectation.fulfill()
                XCTFail("This call should be successful")

        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
}
