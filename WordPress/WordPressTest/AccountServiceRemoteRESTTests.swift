@testable import WordPress

class AccountServiceRemoteRESTTests: RemoteTestCase {

    // MARK: - Constants

    let meEndpoint       = "me"
    let meSitesEndpoint  = "me/sites"

    let getBlogsSuccessMockFilename       = "me-sites-success.json"
    let getBlogsEmptySuccessMockFilename  = "me-sites-empty-success.json"
    let getBlogsFailureMockFilename       = "me-sites-failure.json"

    // MARK: - Properties

    var remote: AccountServiceRemoteREST!

    // MARK: - Overriden Methods

    override func setUp() {
        super.setUp()

        remote = AccountServiceRemoteREST(wordPressComRestApi: restApi)
    }

    // MARK: - Tests

    func testGetBlogsSucceeds() {
        let expect = expectation(description: "Get blogs success")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsSuccessMockFilename, contentType: contentTypeJson)
        remote.getBlogsWithSuccess({ blogs in
            XCTAssertEqual(blogs?.count, 3, "There should be 3 blogs here.")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBlogsWithEmptyResponseArraySucceeds() {
        let expect = expectation(description: "Get blogs with empty response array success")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsEmptySuccessMockFilename, contentType: contentTypeJson)
        remote.getBlogsWithSuccess({ blogs in
            XCTAssertEqual(blogs?.count, 0, "There should be 0 blogs here.")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBlogsFails() {
        let expect = expectation(description: "Get blogs failure")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsFailureMockFilename, contentType: "", status: 500)
        remote.getBlogsWithSuccess({ blogs in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
