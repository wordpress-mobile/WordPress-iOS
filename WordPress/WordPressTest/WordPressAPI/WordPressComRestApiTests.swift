import XCTest
import WordPress
import OHHTTPStubs

class WordPressComRestApiTests: XCTestCase {

    let wordPressComRestApi = "https://public-api.wordpress.com/rest/"
    let wordPressMediaRoute = "v1.1/sites/1/media/"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    private func isRestAPIRequest() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.absoluteString == self.wordPressComRestApi + self.wordPressMediaRoute
        }
    }

    func testSuccessfullCall() {
        stub(isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiMedia.json", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/json"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.GET(wordPressMediaRoute, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTAssert(responseObject is [String:AnyObject], "The response should be a dictionary")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTFail("This call should be successfull")
            }
        )
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testInvalidTokenFailedCall() {
        stub(isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailRequestInvalidToken.json", self.dynamicType)
            return fixture(stubPath!, status:400, headers: ["Content-Type":"application/json"])
        }

        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.GET(wordPressMediaRoute, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == String(WordPressComRestApiError), "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.InvalidToken.rawValue), "The code should be invalid token")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testInvalidJSONFailedCall() {
        stub(isRestAPIRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailInvalidJSON.json", self.dynamicType)
            return fixture(stubPath!, status:400, headers: ["Content-Type":"application/json"])
        }        
        let expectation = self.expectationWithDescription("One callback should be invoked")
        let api = WordPressComRestApi(oAuthToken:"fakeToken")
        api.GET(wordPressMediaRoute, parameters:nil, success: { (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) in
            expectation.fulfill()
            XCTFail("This call should fail")
            }, failure: { (error, httpResponse) in
                expectation.fulfill()
                XCTAssert(error.domain == "NSCocoaErrorDomain", "The error should a NSCocoaErrorDomain")
                XCTAssert(error.code == Int(3840), "The code should be invalid token")
        })
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }

}
