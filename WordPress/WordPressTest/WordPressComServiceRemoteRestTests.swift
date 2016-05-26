import XCTest
@testable import WordPress
import OHHTTPStubs

class WordPressComServiceRemoteRestTests: XCTestCase {

    let wordPressComRestApi = "https://public-api.wordpress.com/rest/"
    let wordPressUsersNewEndpoint = "v1.1/users/new"
    let wordPressSitesNewEndpoint = "v1.1/sites/new"

    var service: WordPressComServiceRemote!
    var api: WordPressComRestApi!

    override func setUp() {
        super.setUp()

        api = WordPressComRestApi()
        service = WordPressComServiceRemote(wordPressComRestApi:api)
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        api = nil
        OHHTTPStubs.removeAllStubs()
    }

    private func isRestAPIUsersNewRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.absoluteString == self.wordPressComRestApi + self.wordPressUsersNewEndpoint
        }
    }

    private func isRestAPISitesNewRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.absoluteString == self.wordPressComRestApi + self.wordPressSitesNewEndpoint
        }
    }

    func testThrottledFailureCall() {
        stub(isRestAPIUsersNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailThrottled.json", self.dynamicType)
            return fixture(stubPath!, status:500, headers: ["Content-Type":"application/html"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        service.createWPComAccountWithEmail("fakeEmail",
                                            andUsername:"fakeUsername",
                                            andPassword:"fakePassword",
                                            success: { (responseObject) in
                                                expectation.fulfill()
                                                XCTFail("This call should fail")
            }, failure: { (error) in
                expectation.fulfill()
                XCTAssert(error.domain == String(reflecting:WordPressComRestApiError.self), "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.TooManyRequests.rawValue), "The error code should be invalid token")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

}
