@testable import WordPress

class AccountServiceRemoteRESTTests: RemoteTestCase {

    // MARK: - Constants

    let meEndpoint       = "me"
    let meSitesEndpoint  = "me/sites"

    let getAccountDetailsSuccessMockFilename        = "me-success.json"
    let getAccountDetailsAuthFailureMockFilename    = "me-auth-failure.json"
    let getAccountDetailsBadJsonFailureMockFilename = "me-bad-json-failure.json"
    let getBlogsSuccessMockFilename                 = "me-sites-success.json"
    let getBlogsEmptySuccessMockFilename            = "me-sites-empty-success.json"
    let getBlogsAuthFailureMockFilename             = "me-sites-auth-failure.json"
    let getBlogsBadJsonFailureMockFilename          = "me-sites-bad-json-failure.json"

    let username = "jimthetester"
    let token = "token"

    // MARK: - Properties

    var remote: AccountServiceRemoteREST!
    var accountService: AccountService!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        accountService = AccountService(managedObjectContext: contextManager.mainContext)
        remote = AccountServiceRemoteREST(wordPressComRestApi: restApi)
    }

    override func tearDown() {
        super.tearDown()
        accountService = nil
    }

    // MARK: - Get Account Details Tests

    func testGetAccountDetailsSucceeds() {
        let expect = expectation(description: "Get account details success")
        let account: WPAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: token)

        stubRemoteResponse(meEndpoint, filename: getAccountDetailsSuccessMockFilename, contentType: contentTypeJson)
        remote.getDetailsFor(account, success: { remoteUser in
            XCTAssertEqual(remoteUser?.username, self.username, "The usernames should be identical")
            expect.fulfill()
        }) { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountDetailsWithServerErrorFails() {
        let expect = expectation(description: "Get account details server error failure")
        let account: WPAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: token)

        stubRemoteResponse(meEndpoint, data: Data(), contentType: nil, status: 500)
        remote.getDetailsFor(account, success: { remoteUser in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountDetailsWithBadAuthFails() {
        let expect = expectation(description: "Get account details with bad auth failure")
        let account: WPAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: token)

        stubRemoteResponse(meEndpoint, filename: getAccountDetailsAuthFailureMockFilename, contentType: contentTypeJson, status: 403)
        remote.getDetailsFor(account, success: { remoteUser in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountDetailsWithBadJsonFails() {
        let expect = expectation(description: "Get account details with invalid json failure")
        let account: WPAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: token)

        stubRemoteResponse(meEndpoint, filename: getAccountDetailsBadJsonFailureMockFilename, contentType: contentTypeJson, status: 200)
        remote.getDetailsFor(account, success: { remoteUser in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Get Blogs Tests

    func testGetBlogsSucceeds() {
        let expect = expectation(description: "Get blogs success")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsSuccessMockFilename, contentType: contentTypeJson)
        remote.getBlogsWithSuccess({ blogs in
            XCTAssertEqual(blogs?.count, 3, "There should be 3 blogs here")
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
            XCTAssertEqual(blogs?.count, 0, "There should be 0 blogs here")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBlogsWithServerErrorFails() {
        let expect = expectation(description: "Get blogs server error failure")
        stubRemoteResponse(meSitesEndpoint, data: Data(), contentType: nil, status: 500)

        remote.getBlogsWithSuccess({ blogs in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBlogsWithBadAuthFails() {
        let expect = expectation(description: "Get blogs auth failure")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsAuthFailureMockFilename, contentType: contentTypeJson, status: 403)
        remote.getBlogsWithSuccess({ blogs in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBlogsWithBadJsonFails() {
        let expect = expectation(description: "Get blogs with invalid json failure")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsBadJsonFailureMockFilename, contentType: contentTypeJson, status: 200)
        remote.getBlogsWithSuccess({ blogs in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
