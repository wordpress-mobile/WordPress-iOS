import XCTest
import WordPressKit
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
        HTTPStubs.removeAllStubs()
    }

    private func isRestAPIUsersNewRequest() -> HTTPStubsTestBlock {
        return { request in
            guard let url = request.url else {
                return false
            }
            return url.absoluteString.contains(self.wordPressUsersNewEndpoint)
        }
    }

    private func isRestAPISitesNewRequest() -> HTTPStubsTestBlock {
        return { request in
            guard let url = request.url else {
                return false
            }
            return url.absoluteString.contains(self.wordPressSitesNewEndpoint)
        }
    }

    func testThrottledFailureCall() throws {
        let stubPath = try XCTUnwrap(
            OHPathForFile("WordPressComRestApiFailThrottled.json", type(of: self))
        )
        stub(condition: isRestAPIUsersNewRequest()) { _ in
            return fixture(
                filePath: stubPath,
                status: 500,
                headers: ["Content-Type" as NSObject: "application/html" as AnyObject]
            )
        }

        let expect = self.expectation(description: "One callback should be invoked")
        service.createWPComAccount(withEmail: "fakeEmail",
                                            andUsername: "fakeUsername",
                                            andPassword: "fakePassword",
                                            andClientID: "moo",
                                            andClientSecret: "cow",
                                            success: { (_) in
                                                expect.fulfill()
                                                XCTFail("This call should fail")
            }, failure: { (error) in
                expect.fulfill()
                let error = error! as NSError
                XCTAssert(error.domain == "WordPressKit.WordPressComRestApiError", "The error should a WordPressComRestApiError")
                XCTAssert(error.code == Int(WordPressComRestApiErrorCode.tooManyRequests.rawValue), "The error code should be too many requests")
        })
        self.waitForExpectations(timeout: 2, handler: nil)
    }

}
