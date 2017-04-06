import XCTest
@testable import WordPress
import OHHTTPStubs

class WordPressComServiceRemoteRestTests: XCTestCase {

    let wordPressUsersNewEndpoint = "v1.1/users/new"
    let wordPressSitesNewEndpoint = "v1.1/sites/new"

    var service: WordPressComServiceRemote!
    var api: WordPressComRestApi!

    override func setUp() {
        super.setUp()

        api = WordPressComRestApi()
        service = WordPressComServiceRemote(wordPressComRestApi: api)
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        api = nil
        OHHTTPStubs.removeAllStubs()
    }

    fileprivate func isRestAPIUsersNewRequest() -> OHHTTPStubsTestBlock {
        return { request in
            guard let url = request.url else {
                return false
            }
            return url.absoluteString.contains(self.wordPressUsersNewEndpoint)
        }
    }

    fileprivate func isRestAPISitesNewRequest() -> OHHTTPStubsTestBlock {
        return { request in
            guard let url = request.url else {
                return false
            }
            return url.absoluteString.contains(self.wordPressSitesNewEndpoint)
        }
    }

    func testThrottledFailureCall() {
        stub(condition: isRestAPIUsersNewRequest()) { request in
            let stubPath = OHPathForFile("WordPressComRestApiFailThrottled.json", type(of: self))
            return fixture(filePath: stubPath!, status: 500, headers: ["Content-Type" as NSObject: "application/html" as AnyObject])
        }

        let expect = self.expectation(description: "One callback should be invoked")
        service.createWPComAccount(withEmail: "fakeEmail",
                                            andUsername: "fakeUsername",
                                            andPassword: "fakePassword",
                                            andLocale: "en",
                                            success: { (responseObject) in
                                                expect.fulfill()
                                                XCTFail("This call should fail")
            }, failure: { (error) in
                expect.fulfill()
                let error = error! as NSError
                XCTAssert(error.domain == String(reflecting: WordPressComRestApiError.self), "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiError.tooManyRequests.rawValue), "The error code should be invalid token")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

}
