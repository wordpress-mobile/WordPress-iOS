@testable import WordPress

class AccountSettingsRemoteTests: RemoteTestCase {

    // MARK: - Constants

    let siteID   = 321
    let username = "jimthetester"
    let email    = "jimthetester@thetestemail.org"
    let token    = "token"
    let userURL  = "http://jimthetester.blog"

    let meSettingsEndpoint  = "me/settings"

    let getAccountSettingsSuccessMockFilename        = "me-settings-success.json"
    let getAccountSettingsAuthFailureMockFilename    = "me-settings-auth-failure.json"
    let getAccountSettingsBadJsonFailureMockFilename = "me-settings-bad-json-failure.json"

    // MARK: - Properties

    var remote: AccountSettingsRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = AccountSettingsRemote.remoteWithApi(restApi)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Get Account Settings Tests

    func testGetAccountSettingsSucceeds() {
        let expect = expectation(description: "Get account settings success")

        stubRemoteResponse(meSettingsEndpoint, filename: getAccountSettingsSuccessMockFilename, contentType: .ApplicationJSON)
        remote.getSettings(success: { settings in
            XCTAssertEqual(settings.username, self.username, "The usernames should be equal.")
            XCTAssertEqual(settings.email, self.email, "The email addresses should be equal.")
            XCTAssertEqual(settings.webAddress, self.userURL, "The web addresses should be equal.")
            XCTAssertEqual(settings.primarySiteID, self.siteID, "The primary site ID's should be equal.")
            expect.fulfill()
        }) { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountSettingsWithServerErrorFails() {
        let expect = expectation(description: "Get account settings server error failure")

        stubRemoteResponse(meSettingsEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.getSettings(success: { settings in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountSettingsWithBadAuthFails() {
        let expect = expectation(description: "Get account settings with bad auth failure")

        stubRemoteResponse(meSettingsEndpoint, filename: getAccountSettingsAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getSettings(success: { settings in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetAccountSettingsWithBadJsonFails() {
        let expect = expectation(description: "Get account settings with invalid json response failure")

        stubRemoteResponse(meSettingsEndpoint, filename: getAccountSettingsBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getSettings(success: { settings in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
