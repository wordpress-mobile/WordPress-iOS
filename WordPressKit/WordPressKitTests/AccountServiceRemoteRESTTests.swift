@testable import WordPress

class AccountServiceRemoteRESTTests: RemoteTestCase {

    // MARK: - Constants

    let siteID   = 321
    let username = "jimthetester"
    let email    = "jimthetester@thetestemail.org"
    let token    = "token"

    let meEndpoint       = "me"
    let meSitesEndpoint  = "me/sites"
    let emailEndpoint    = "/is-available/email"
    let usernameEndpoint = "/is-available/username"
    let linkEndpoint     = "auth/send-login-email"

    let getAccountDetailsSuccessMockFilename        = "me-success.json"
    let getAccountDetailsAuthFailureMockFilename    = "me-auth-failure.json"
    let getAccountDetailsBadJsonFailureMockFilename = "me-bad-json-failure.json"
    let getBlogsSuccessMockFilename                 = "me-sites-success.json"
    let getBlogsEmptySuccessMockFilename            = "me-sites-empty-success.json"
    let getBlogsAuthFailureMockFilename             = "me-sites-auth-failure.json"
    let getBlogsBadJsonFailureMockFilename          = "me-sites-bad-json-failure.json"
    let setSiteVisibilitySuccessMockFilename        = "me-sites-visibility-success.json"
    let setSiteVisibilityFailureMockFilename        = "me-sites-visibility-failure.json"
    let setSiteVisibilityBadJsonFailureMockFilename = "me-sites-visibility-bad-json-failure.json"
    let isEmailAvailableSuccessMockFilename         = "is-available-email-success.json"
    let isEmailAvailableFailureMockFilename         = "is-available-email-failure.json"
    let isUsernameAvailableSuccessMockFilename      = "is-available-username-success.json"
    let isUsernameAvailableFailureMockFilename      = "is-available-username-failure.json"
    let requestLinkSuccessMockFilename              = "auth-send-login-email-success.json"
    let requestLinkNoSuchUserFailureMockFilename    = "auth-send-login-email-no-user-failure.json"
    let requestLinkInvalidClientFailureMockFilename = "auth-send-login-email-invalid-client-failure.json"
    let requestLinkInvalidSecretFailureMockFilename = "auth-send-login-email-invalid-secret-failure.json"

    // MARK: - Properties

    var remote: AccountServiceRemoteREST!
    var account: WPAccount!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = AccountServiceRemoteREST(wordPressComRestApi: restApi)
        account = NSEntityDescription.insertNewObject(forEntityName: "Account", into: testContextManager.mainContext) as! WPAccount
        account.username = username
        account.email = email
        account.authToken = token
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Get Account Details Tests

    func testGetAccountDetailsSucceeds() {
        let expect = expectation(description: "Get account details success")

        stubRemoteResponse(meEndpoint, filename: getAccountDetailsSuccessMockFilename, contentType: .ApplicationJSON)
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

        stubRemoteResponse(meEndpoint, data: Data(), contentType: .NoContentType, status: 500)
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

        stubRemoteResponse(meEndpoint, filename: getAccountDetailsAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
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
        let expect = expectation(description: "Get account details with invalid json response failure")

        stubRemoteResponse(meEndpoint, filename: getAccountDetailsBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
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

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsSuccessMockFilename, contentType: .ApplicationJSON)
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

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsEmptySuccessMockFilename, contentType: .ApplicationJSON)
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
        stubRemoteResponse(meSitesEndpoint, data: Data(), contentType: .NoContentType, status: 500)

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

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
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
        let expect = expectation(description: "Get blogs with invalid json response failure")

        stubRemoteResponse(meSitesEndpoint, filename: getBlogsBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getBlogsWithSuccess({ blogs in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Update Blog Visibility Tests

    func testUpdateBlogVisibilitySucceeds() {
        let expect = expectation(description: "Update blog visibility success")

        stubRemoteResponse(meSitesEndpoint, filename: setSiteVisibilitySuccessMockFilename, contentType: .ApplicationJSON)
        let blogsToChangeVisibility: [NSNumber: Bool] = [NSNumber(value: Int32(siteID)): true]
        remote.updateBlogsVisibility(blogsToChangeVisibility, success: {
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateBlogVisibilityWithUnauthorizedSiteFails() {
        let expect = expectation(description: "Update blog visibility server error failure")

        stubRemoteResponse(meSitesEndpoint, filename: setSiteVisibilityFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        let blogsToChangeVisibility: [NSNumber: Bool] = [NSNumber(value: Int32(siteID)): true]
        remote.updateBlogsVisibility(blogsToChangeVisibility, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorizationRequired")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testUpdateBlogVisibilityWithServerErrorFails() {
        let expect = expectation(description: "Update blog visibility server error failure")

        stubRemoteResponse(meSitesEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        let blogsToChangeVisibility: [NSNumber: Bool] = [NSNumber(value: Int32(siteID)): true]
        remote.updateBlogsVisibility(blogsToChangeVisibility, success: {
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

    func testUpdateBlogVisibilityWithBadJsonFails() {
        let expect = expectation(description: "Update blog visibility with invalid json response failure")

        stubRemoteResponse(meEndpoint, filename: setSiteVisibilityBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        let blogsToChangeVisibility: [NSNumber: Bool] = [NSNumber(value: Int32(siteID)): true]
        remote.updateBlogsVisibility(blogsToChangeVisibility, success: {
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Is Email Available Tests

    func testIsEmailAvailableSucceeds() {
        let expect = expectation(description: "Email check success")

        stubRemoteResponse(emailEndpoint, filename: isEmailAvailableSuccessMockFilename, contentType: .JavaScript)
        remote.isEmailAvailable(email, success: { isAvailable in
            XCTAssertTrue(isAvailable)
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testIsEmailAvailableFails() {
        let expect = expectation(description: "Email check failure")

        stubRemoteResponse(emailEndpoint, filename: isEmailAvailableFailureMockFilename, contentType: .JavaScript)
        remote.isEmailAvailable(email, success: { isAvailable in
            XCTAssertFalse(isAvailable)
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testIsEmailAvailableWithServerErrorFails() {
        let expect = expectation(description: "Email check server error failure")

        stubRemoteResponse(emailEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.isEmailAvailable(email, success: { isAvailable in
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

    // MARK: - Is Username Available Tests

    func testIsUsernameAvailableSucceeds() {
        let expect = expectation(description: "Username check success")

        stubRemoteResponse(usernameEndpoint, filename: isUsernameAvailableSuccessMockFilename, contentType: .JavaScript)
        remote.isUsernameAvailable(username, success: { isAvailable in
            XCTAssertTrue(isAvailable)
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testIsUsernameAvailableFails() {
        let expect = expectation(description: "Username check failure")

        stubRemoteResponse(usernameEndpoint, filename: isUsernameAvailableFailureMockFilename, contentType: .JavaScript)
        remote.isUsernameAvailable(username, success: { isAvailable in
            XCTAssertFalse(isAvailable)
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testIsUsernameAvailableWithServerErrorFails() {
        let expect = expectation(description: "Username check server error failure")

        stubRemoteResponse(usernameEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.isUsernameAvailable(username, success: { isAvailable in
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

    // MARK: - Request WPCom Auth Link For Email Tests

    func testRequestWPComAuthLinkSucceeds() {
        let expect = expectation(description: "Request WPCom Auth Link success")

        stubRemoteResponse(linkEndpoint, filename: requestLinkSuccessMockFilename, contentType: .ApplicationJSON)
        remote.requestWPComAuthLink(forEmail: email, success: {
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testRequestWPComAuthLinkWithBadEmailAddressFails() {
        let expect = expectation(description: "Request WPCom Auth Link with bad email address fails")

        stubRemoteResponse(linkEndpoint, filename: requestLinkNoSuchUserFailureMockFilename, contentType: .ApplicationJSON, status: 404)
        remote.requestWPComAuthLink(forEmail: email, success: {
            expect.fulfill()
            XCTFail("This callback shouldn't get called")
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

    func testRequestWPComAuthLinkWithBadClientIdFails() {
        let expect = expectation(description: "Request WPCom Auth Link with bad client ID fails")

        stubRemoteResponse(linkEndpoint, filename: requestLinkInvalidClientFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.requestWPComAuthLink(forEmail: email, success: {
            expect.fulfill()
            XCTFail("This callback shouldn't get called")
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

    func testRequestWPComAuthLinkWithBadSecretFails() {
        let expect = expectation(description: "Request WPCom Auth Link with bad secret fails")

        stubRemoteResponse(linkEndpoint, filename: requestLinkInvalidSecretFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.requestWPComAuthLink(forEmail: email, success: {
            expect.fulfill()
            XCTFail("This callback shouldn't get called")
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

    func testRequestWPComAuthLinkWithServerErrorFails() {
        let expect = expectation(description: "Request WPCom Auth Link with server error failure")

        stubRemoteResponse(linkEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.requestWPComAuthLink(forEmail: email, success: {
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
}
